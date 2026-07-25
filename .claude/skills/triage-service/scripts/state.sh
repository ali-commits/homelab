#!/usr/bin/env bash
# state.sh — gather everything needed to diagnose one RedRipper service.
#
# Read-only. Makes no changes, so it is safe to run before you understand the
# problem — which is the point: gather first, theorise second.
#
# Usage: state.sh <service> [repo_root]

set -uo pipefail

SVC="${1:-}"
ROOT="${2:-/HOMELAB}"
[ -n "$SVC" ] || { echo "usage: state.sh <service> [repo_root]"; exit 2; }
cd "$ROOT" 2>/dev/null || { echo "cannot cd to $ROOT"; exit 2; }

sec() { printf '\n=== %s ===\n' "$1"; }

# ------------------------------------------------------------------ identity --
sec "Service definition"
if [ -d "services/$SVC" ]; then
    echo "dir:      services/$SVC"
    printf 'image:    %s\n' "$(grep -m1 -oE 'image:[[:space:]]*[^[:space:]#]+' "services/$SVC/compose.yml" 2>/dev/null | sed -E 's/image:[[:space:]]*//')"
    printf 'restart:  %s\n' "$(grep -m1 -oE "restart:[[:space:]]*['\"]?[a-z-]+" "services/$SVC/compose.yml" 2>/dev/null | sed -E "s/restart:[[:space:]]*['\"]?//")"
    # A stack can route several hostnames (opencloud serves drive + onlyoffice,
    # zitadel serves the API and the v2 login UI), so collect all of them.
    DOMAINS=$(grep -oE 'rule=Host\(`[^`]+`\)' "services/$SVC/compose.yml" 2>/dev/null |
              sed -E 's/rule=Host\(`//;s/`\)//' | sort -u)
    DOMAIN=$(head -1 <<<"$DOMAINS")
    echo "domains:  $(echo $DOMAINS | tr '\n' ' ')"
    CONTAINERS=$(grep -oE 'container_name:[[:space:]]*[A-Za-z0-9._-]+' "services/$SVC/compose.yml" 2>/dev/null |
                 awk '{print $2}')
    echo "declares: $(echo $CONTAINERS | tr '\n' ' ')"
else
    echo "NO services/$SVC directory — this may be an unmanaged container."
    CONTAINERS="$SVC"
    DOMAIN=""
fi

# ------------------------------------------------------------------- sablier --
# Checked before anything else: for a Sablier-managed service, "not running" is
# the correct steady state, not a fault. Starting it by hand defeats the design.
sec "Sablier status"
SABLIER=$(grep -m1 -oE 'SABLIER_SERVICES=\([^)]*\)' scripts/start-all.sh 2>/dev/null |
          sed -E 's/SABLIER_SERVICES=\(//;s/\)//')
if grep -qw -- "$SVC" <<<"$SABLIER"; then
    echo "MANAGED — this service is expected to sit stopped until a request wakes it."
    echo "A stopped container is therefore NOT evidence of a fault."
    echo "Test waking it instead of starting it by hand:"
    [ -n "${DOMAIN:-}" ] && echo "    curl -s -o /dev/null -w '%{http_code}\\n' https://$DOMAIN"
    grep -m1 -E "restart:" "services/$SVC/compose.yml" 2>/dev/null |
        grep -qE "unless-stopped|always" &&
        echo "  WARNING: restart policy is unless-stopped/always — it can never stay scaled to zero."
else
    echo "not Sablier-managed — it should be running continuously."
fi

# ----------------------------------------------------------------- containers --
sec "Container state"
for c in $CONTAINERS; do
    if docker inspect "$c" >/dev/null 2>&1; then
        docker inspect "$c" --format \
          '{{.Name}}: {{.State.Status}} (exit={{.State.ExitCode}} restarts={{.RestartCount}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}) since {{.State.StartedAt}}' \
          2>/dev/null | sed 's|^/||'
    else
        echo "$c: NOT CREATED"
    fi
done

# ---------------------------------------------------------------------- logs --
sec "Recent logs (last 40 lines per container)"
for c in $CONTAINERS; do
    printf -- '--- %s ---\n' "$c"
    docker logs "$c" --tail 40 2>&1 | tail -40 || echo "(no logs)"
done

# ------------------------------------------------------------------ networks --
sec "Network attachment"
for c in $CONTAINERS; do
    nets=$(docker inspect "$c" --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}' 2>/dev/null)
    echo "$c: ${nets:-<not running>}"
done
echo "(a Traefik-routed container must be on 'proxy'; a database should NOT be)"

# -------------------------------------------------------------------- tunnel --
# The tunnel sits above Traefik: if the hostname is not in its ingress config the
# request never reaches the homelab at all, and every container-level check will
# look perfectly healthy while the site is down from outside.
sec "Cloudflare tunnel"
if command -v flared >/dev/null 2>&1; then
    if [ -n "${DOMAINS:-}" ]; then
        # Capture before matching rather than piping into `grep -q`: grep exits at
        # the first hit, flared then takes SIGPIPE, and `set -o pipefail` reports
        # the pipeline as failed even on a successful match.
        TUNNEL_LIST=$(flared list 2>/dev/null || true)
        while read -r d; do
            [ -n "$d" ] || continue
            hits=$(grep -c "^${d}[[:space:]]" <<<"$TUNNEL_LIST")
            case "$hits" in
                0) echo "$d: NOT in tunnel ingress — unreachable from the internet."
                   echo "    A healthy container cannot compensate for this. Fix: flared add ${d%%.*}" ;;
                1) echo "$d: routed via tunnel" ;;
                *) echo "$d: $hits duplicate ingress entries — only the first is used, the rest are dead config" ;;
            esac
        done <<<"$DOMAINS"
    else
        echo "(no Host() rule found in compose — nothing to check)"
    fi
else
    echo "(flared not on PATH — skipping)"
fi

# ------------------------------------------------------------------- traefik --
sec "Traefik routing"
if docker ps --format '{{.Names}}' | grep -qx traefik; then
    echo "traefik: running"
    if [ -n "${DOMAIN:-}" ]; then
        echo "labels declared in compose:"
        grep -E 'traefik\.' "services/$SVC/compose.yml" 2>/dev/null | sed 's/^ *- */  /' | head -20
    fi
else
    echo "traefik is NOT running — every service will appear down. Fix Traefik first."
fi

# --------------------------------------------------------------- port binding --
sec "Host port 443 owner"
# A recurring failure: `tailscale serve` claims :443 before Traefik can bind it,
# which takes down every service at once while each container looks healthy.
ss -tlnp 2>/dev/null | awk 'NR==1 || /:443 /' || echo "(ss unavailable)"

# -------------------------------------------------------------------- storage --
sec "Storage pressure"
df -h / /storage/data 2>/dev/null | grep -v '^Filesystem'
echo "(a full NVMe presents as unrelated services failing to write)"

echo
echo "Gathered. Interpret with the red-herring catalogue in SKILL.md before acting."
