#!/usr/bin/env bash
# audit.sh — compare RedRipper's documentation against the live system.
#
# Every check compares a documented claim against a command whose output is
# ground truth. Nothing is inferred: if a check fires, someone wrote something
# that reality no longer agrees with.
#
# Drift is recorded in a temp file rather than a shell variable because several
# checks run inside pipelines, and a pipeline's `while` loop runs in a subshell
# where variable assignments would be lost.
#
# Usage:  audit.sh [repo_root]      (default: /HOMELAB)
# Exit:   0 = no drift, 1 = drift found, 2 = cannot run

set -uo pipefail

ROOT="${1:-/HOMELAB}"
cd "$ROOT" 2>/dev/null || { echo "cannot cd to $ROOT"; exit 2; }
[ -d services ] || { echo "$ROOT does not look like the homelab repo (no services/)"; exit 2; }

DRIFT_FILE=$(mktemp); trap 'rm -f "$DRIFT_FILE"' EXIT

section() { printf '\n== %s ==\n' "$1"; }
flag()    { printf '  DRIFT  %s\n' "$1"; echo x >>"$DRIFT_FILE"; }
ok()      { printf '  ok     %s\n' "$1"; }
note()    { printf '  note   %s\n' "$1"; }

SERVICES=$(find services -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
SERVICE_COUNT=$(printf '%s\n' "$SERVICES" | grep -c .)

# ---------------------------------------------------------------- structure --
section "Service directory structure ($SERVICE_COUNT services)"
missing=0
for s in $SERVICES; do
    [ -f "services/$s/compose.yml" ]      || { flag "services/$s has no compose.yml"; missing=1; }
    [ -f "services/$s/documentation.md" ] || { flag "services/$s has no documentation.md"; missing=1; }
done
[ "$missing" -eq 0 ] && ok "every service has compose.yml + documentation.md"

# ------------------------------------------------------------ service index --
section "Master service index (docs/docker/00_README.md)"
INDEX=docs/docker/00_README.md
if [ -f "$INDEX" ]; then
    idx_bad=0
    # Match on the link target rather than the bold display label. Display names
    # legitimately differ from directory names ("Vert.sh" -> services/vert), so a
    # label-based check produces false positives; the link target is unambiguous.
    TARGETS=$(grep -oE 'services/[a-z0-9._-]+/compose\.yml' "$INDEX" |
              sed -E 's|services/||;s|/compose\.yml||' | sort)
    for s in $SERVICES; do
        n=$(grep -cx -- "$s" <<<"$TARGETS")
        [ "$n" -eq 0 ] && { flag "$s is missing from the index table in $INDEX"; idx_bad=1; }
    done
    # A stack may legitimately occupy several rows when it exposes more than one
    # routed endpoint (opencloud and opencloud-onlyoffice share a compose file but
    # answer on different ports and domains). A row is only redundant when another
    # row points at the same service *and* claims the same domain.
    while read -r n svc dom; do
        [ "${n:-0}" -gt 1 ] || continue
        flag "$svc has $n index rows sharing domain '$dom' (duplicate entry)"
        idx_bad=1
    done < <(awk -F'|' '/^\| *\[/ {
                 if (match($2, /services\/[a-z0-9._-]+\/compose\.yml/)) {
                     t = substr($2, RSTART, RLENGTH)
                     gsub(/services\/|\/compose\.yml/, "", t)
                     d = $6; gsub(/^[ \t]+|[ \t]+$/, "", d)
                     print t, d
                 }
             }' "$INDEX" | sort | uniq -c)
    while read -r row; do
        [ -n "$row" ] || continue
        [ -d "services/$row" ] || { flag "index links to services/$row which does not exist"; idx_bad=1; }
    done < <(printf '%s\n' "$TARGETS" | sort -u)
    [ "$idx_bad" -eq 0 ] && ok "index lists exactly the $SERVICE_COUNT services, no duplicates or dead rows"
else
    flag "$INDEX not found"
fi

# --------------------------------------------------------------- categories --
section "Category docs (docs/docker/03..10)"
cat_bad=0
for s in $SERVICES; do
    grep -rql "services/$s/documentation.md" docs/docker/0[3-9]_*.md docs/docker/10_*.md 2>/dev/null \
        || { flag "$s is not listed in any docs/docker category file"; cat_bad=1; }
done
[ "$cat_bad" -eq 0 ] && ok "every service appears in a category doc"

# ------------------------------------------------------------ service count --
section "Service counts in prose"
count_bad=0
for f in README.md CLAUDE.md AGENTS.md docs/docker/00_README.md; do
    [ -f "$f" ] || continue
    while IFS=: read -r line match; do
        [ -n "$match" ] || continue
        # Sablier rows legitimately cite their own smaller count ("scaling for 13
        # services"); those are checked against start-all.sh further down instead.
        srcline=$(sed -n "${line}p" "$f")
        case "$srcline" in *[Ss]ablier*|*wake-on-demand*) continue ;; esac
        num=${match%%[!0-9]*}
        # "40+" is a deliberately soft claim — only wrong if reality dropped below it.
        case "$match" in
            *+*) [ "$SERVICE_COUNT" -ge "$num" ] || { flag "$f:$line claims '$match' but only $SERVICE_COUNT service dirs exist"; count_bad=1; } ;;
            *)   [ "$num" = "$SERVICE_COUNT" ]  || { flag "$f:$line claims '$match' but $SERVICE_COUNT service dirs exist"; count_bad=1; } ;;
        esac
    done < <(grep -noE '\b[0-9]{2}\+? (containerized |Production |deployed )?[Ss]ervices?' "$f")
done
[ "$count_bad" -eq 0 ] && ok "prose service counts agree with $SERVICE_COUNT"

# ----------------------------------------------------------------- versions --
section "Image tags vs documented versions"
ver_bad=0
for s in $SERVICES; do
    doc="services/$s/documentation.md"
    [ -f "$doc" ] || continue
    tag=$(grep -m1 -oE 'image:[[:space:]]*[^[:space:]#]+' "services/$s/compose.yml" 2>/dev/null |
          sed -E 's/image:[[:space:]]*//' | awk -F: '{print $NF}')
    # Only meaningful when pinned to a real version (skip latest/nightly/digests)
    case "$tag" in ''|latest|nightly|*[!0-9.v-]*) continue ;; esac
    # Only complain when the doc actually states a version somewhere
    grep -qiE '\| *Version|version *\|' "$doc" || continue
    grep -qF "$tag" "$doc" || { flag "$s: image pinned to '$tag' but that string is absent from $doc"; ver_bad=1; }
done
[ "$ver_bad" -eq 0 ] && ok "pinned image tags match their documentation"

# ------------------------------------------------------------------ sablier --
section "Sablier wake-on-demand set"
SABLIER_LINE=$(grep -m1 -oE 'SABLIER_SERVICES=\([^)]*\)' scripts/start-all.sh 2>/dev/null)
if [ -n "$SABLIER_LINE" ]; then
    SABLIER=$(echo "$SABLIER_LINE" | sed -E 's/SABLIER_SERVICES=\(//;s/\)//' | tr ' ' '\n' | grep . | sort)
    SABLIER_COUNT=$(printf '%s\n' "$SABLIER" | grep -c .)
    ok "start-all.sh manages $SABLIER_COUNT services: $(echo $SABLIER | tr '\n' ' ')"

    for s in $SABLIER; do
        [ -d "services/$s" ] || flag "sablier list names '$s' but services/$s does not exist"
        # A restart policy of unless-stopped/always defeats scale-to-zero: Docker
        # brings the container straight back after start-all.sh stops it.
        if [ -f "services/$s/compose.yml" ] &&
           grep -qE "restart:[[:space:]]*['\"]?(unless-stopped|always)" "services/$s/compose.yml"; then
            flag "$s is Sablier-managed but sets restart: unless-stopped/always — it will not stay scaled to zero"
        fi
    done

    for f in CLAUDE.md AGENTS.md; do
        [ -f "$f" ] || continue
        for s in $SABLIER; do
            grep -q "wake-on-demand.*\b$s\b" "$f" || flag "$f Sablier enumeration omits '$s'"
        done
    done

    while IFS=: read -r f line match; do
        [ -n "$match" ] || continue
        num=${match%%[!0-9]*}
        [ "$num" = "$SABLIER_COUNT" ] || flag "$f:$line claims '$match' but start-all.sh manages $SABLIER_COUNT"
    done < <(grep -rnoE '[0-9]{1,2} (low-traffic services|managed via Sablier|services to zero)' \
             CLAUDE.md AGENTS.md docs/docker/00_README.md 2>/dev/null)
else
    note "could not find SABLIER_SERVICES in scripts/start-all.sh"
fi

# ------------------------------------------------------------ storage paths --
section "Storage mount paths"
if command -v findmnt >/dev/null 2>&1; then
    MOUNTS=$(findmnt -rno TARGET -t btrfs 2>/dev/null | grep '^/storage' | sort -u)
    ok "live btrfs mounts: $(echo $MOUNTS | tr '\n' ' ')"
    path_bad=0
    while read -r p; do
        [ -n "$p" ] || continue
        grep -qx "$p" <<<"$MOUNTS" && continue
        [ -e "$p" ] && continue          # a real subdirectory of a mount is fine
        flag "docs reference '$p' which is neither a mount nor an existing path"
        path_bad=1
    # -h strips filenames, so directories must be excluded at the grep level.
    # Skill docs under .claude/ deliberately quote wrong paths as examples.
    done < <(grep -rhoE '/storage/[A-Za-z0-9_-]+' --include='*.md' \
                  --exclude-dir=.claude --exclude-dir=graphify-out . 2>/dev/null | sort -u)
    [ "$path_bad" -eq 0 ] && ok "every /storage path cited in docs exists"
else
    note "findmnt unavailable — skipping storage check"
fi

# ----------------------------------------------------- cloudflare tunnel map --
# A service is only reachable from the internet if its hostname exists in the
# tunnel ingress config. Traefik labels alone are not enough — the request never
# arrives. `flared` manages both the ingress route and the proxied CNAME.
section "Cloudflare tunnel hostnames"
if command -v flared >/dev/null 2>&1 && TUNNEL_RAW=$(flared list 2>/dev/null); then
    TUNNEL=$(printf '%s\n' "$TUNNEL_RAW" | tail -n +5 | awk '{print $1}' |
             grep -F '.alimunee.com' | sed 's/\.alimunee\.com$//' | sort -u)
    ROUTED=$(grep -rhoE 'rule=Host\(`[^`]+`\)' services/*/compose.yml 2>/dev/null |
             sed -E 's/rule=Host\(`//;s/`\)//' | grep -F '.alimunee.com' |
             sed 's/\.alimunee\.com$//' | sort -u)

    # Routed but not tunnelled: the service answers locally and is dead publicly.
    while read -r h; do
        [ -n "$h" ] || continue
        flag "'$h.alimunee.com' has a Traefik router but no tunnel hostname — unreachable externally (fix: flared add $h)"
    done < <(comm -23 <(printf '%s\n' "$ROUTED") <(printf '%s\n' "$TUNNEL"))

    # Tunnelled but not routed: usually a decommissioned service whose route and
    # DNS record were never removed. Reported as a note because a few hostnames
    # are legitimately served by something other than a Traefik router.
    stale=$(comm -13 <(printf '%s\n' "$ROUTED") <(printf '%s\n' "$TUNNEL") | tr '\n' ' ')
    [ -n "${stale// /}" ] && note "tunnel hostnames with no Traefik router (review; 'flared delete <name>' also removes the DNS record): $stale"

    # Duplicate ingress entries: only the first match wins, so the rest are dead
    # config that still has to be maintained and read.
    dupes=$(printf '%s\n' "$TUNNEL_RAW" | tail -n +5 | awk '{print $1}' |
            grep -F '.alimunee.com' | sort | uniq -d | tr '\n' ' ')
    [ -n "${dupes// /}" ] && flag "duplicate tunnel ingress entries (only the first is used): $dupes"
    ok "tunnel exposes $(printf '%s\n' "$TUNNEL" | grep -c .) hostnames for $(printf '%s\n' "$ROUTED" | grep -c .) routed services"
else
    note "flared unavailable or tunnel unreachable — skipping tunnel check"
fi

# ------------------------------------------------------- orphaned containers --
section "Running containers vs repo"
if docker ps --format '{{.Names}}' >/dev/null 2>&1; then
    orph=0
    for c in $(docker ps --format '{{.Names}}'); do
        proj=$(docker inspect "$c" --format '{{index .Config.Labels "com.docker.compose.project"}}' 2>/dev/null)
        [ -n "$proj" ] && [ -d "services/$proj" ] && continue
        matched=0
        for s in $SERVICES; do
            case "$c" in "$s"|"$s"-*|"$s"_*) matched=1; break ;; esac
        done
        [ "$matched" -eq 1 ] || { flag "container '$c' runs but has no services/ directory (unmanaged — will not survive start-all.sh)"; orph=1; }
    done
    [ "$orph" -eq 0 ] && ok "every running container maps to a service directory"
else
    note "docker not accessible — skipping orphan check"
fi

# ------------------------------------------------------------- doc integrity --
section "Doc integrity"
if [ -f CLAUDE.md ] && [ -f AGENTS.md ]; then
    cmp -s CLAUDE.md AGENTS.md && ok "CLAUDE.md and AGENTS.md are in sync" \
        || flag "CLAUDE.md and AGENTS.md have diverged (they are maintained as identical copies)"
fi
# Broken links cluster: one wrong prefix in a table breaks every row. Reporting
# each one buries the signal, so group by file and show a representative example
# plus the depth-corrected path that would have worked.
BROKEN=$(mktemp); trap 'rm -f "$DRIFT_FILE" "$BROKEN"' EXIT
while IFS=: read -r f line link; do
    [ -n "$link" ] || continue
    target=${link#*\](}; target=${target%\)}; target=${target%%#*}
    [ -z "$target" ] && continue
    [ -e "$(dirname "$f")/$target" ] || printf '%s\t%s\t%s\n' "$f" "$line" "$target" >>"$BROKEN"
done < <(grep -rnoE '\]\(\.\.?/[^)]+\)' --include='*.md' . 2>/dev/null |
         grep -vE 'graphify-out|/\.claude/')

if [ -s "$BROKEN" ]; then
    cut -f1 "$BROKEN" | sort | uniq -c | sort -rn | while read -r n f; do
        ex=$(grep -m1 -P "^\Q$f\E\t" "$BROKEN" | cut -f3)
        hint=""
        # Suggest a fix when simply adding one more ../ resolves it — the usual
        # cause is a table written at the wrong directory depth.
        [ -e "$(dirname "$f")/../$ex" ] && hint="  (adding one '../' resolves it)"
        flag "$f: $n broken relative link(s), e.g. '$ex'$hint"
    done
else
    ok "all relative doc links resolve"
fi

# ----------------------------------------------------------------------------
TOTAL=$(grep -c . "$DRIFT_FILE" 2>/dev/null || echo 0)
printf '\n----------------------------------------\n'
if [ "$TOTAL" -eq 0 ]; then
    echo "No drift detected."
    exit 0
fi
echo "$TOTAL drift item(s) found — see DRIFT lines above."
exit 1
