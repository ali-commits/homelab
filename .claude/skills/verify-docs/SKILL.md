---
name: verify-docs
description: Audit the RedRipper homelab's documentation against the live system to find stale versions, wrong service counts, missing index rows, bad storage paths, broken links, and unmanaged containers. Use this whenever the user asks to check, audit, verify, refresh, or update the docs; after upgrading a service image; after adding or removing a service; before a commit that touches documentation; or when someone asks "are the docs still accurate?" or "what's out of date?". Also use it proactively as the verification step at the end of any task that changed compose files, storage layout, or the Sablier set.
---

# Verify docs against the live system

Documentation in this repo rots quietly. A `docker compose` edit takes one line;
keeping `CLAUDE.md`, `AGENTS.md`, `README.md`, the master index, and the service's
own `documentation.md` in agreement takes five. The gap is invisible until someone
trusts a stale number.

This skill closes that gap by never asking "does this look right?" — instead every
documented claim is compared against a command whose output *is* the truth.

## Run the audit first

```bash
bash .claude/skills/verify-docs/scripts/audit.sh /HOMELAB
```

Exit code is 0 when clean, 1 when drift was found. Run this before reading any
docs by hand; it takes seconds and tells you exactly where to look.

## What it checks, and why each one catches real bugs

| Check | Ground truth | The bug it catches |
|---|---|---|
| Service structure | `services/*/` contents | a service with no `documentation.md` |
| Master index | `services/*/` vs `00_README.md` rows | a service added but never indexed |
| Category docs | `services/*/` vs `docs/docker/0[3-9],10` | a service indexed but uncategorised |
| Prose counts | `ls -d services/*/ \| wc -l` | "39 services" long after it became 42 |
| Image versions | `image:` tag vs the service's doc | Traefik bumped to 3.7, doc still says 3.5 |
| Sablier set | `SABLIER_SERVICES` in `start-all.sh` | prose omitting a managed service |
| Sablier restart policy | `restart:` in each managed compose | a service that can never scale to zero |
| Storage paths | `findmnt -t btrfs` | docs citing `/storage/share` when it's `/storage/shared` |
| Orphan containers | `docker ps` vs `services/*/` | a container started by hand, absent from the repo |
| CLAUDE/AGENTS sync | `cmp` | the two copies drifting apart |
| Relative links | filesystem | a table written at the wrong directory depth |

## Interpreting results

The script reports facts; deciding what to do needs judgment. A few cases where
the honest answer is "not a bug":

**Soft counts.** `40+ services` stays true at 42. The script only flags a `N+`
claim when reality dropped *below* N. Don't "fix" these into exact numbers unless
the surrounding text is trying to be precise.

**Sablier's own numbers.** The index row for `sablier` says "wake-on-demand
scaling for 13 services" — that's a different quantity from the total service
count, and it's validated separately against `start-all.sh`.

**Unpinned images.** Most services run `:latest`, so there's no version to
compare. The check only fires on genuinely pinned tags, which is where a stale
doc actually misleads.

**Orphan containers are a finding, not necessarily an error.** A container with
no `services/` directory won't survive `start-all.sh` and isn't captured by the
repo. That may be a deliberate experiment. Report it and ask; don't quietly
author a compose file for it.

## Fixing what you find

Work from the ground truth outward, and re-run the script after each fix rather
than batching blindly.

- **Two files, one edit.** `CLAUDE.md` and `AGENTS.md` are maintained as
  byte-identical copies. Edit `CLAUDE.md`, then `cp CLAUDE.md AGENTS.md`, and let
  the script's `cmp` check confirm it.
- **Broken links usually cluster.** When one table row has the wrong `../` depth,
  every row does. The script reports a count and a suggested fix per file rather
  than 88 individual lines — fix the prefix once with `sed`, then re-run.
- **Storage paths.** Before rewriting a path, confirm what it should be with
  `findmnt -t btrfs`. A path that doesn't exist may mean the doc is stale *or*
  that a directory was never created — those need different fixes.
- **Version tables.** The compose file is authoritative. If a doc states a
  version, it must match the pinned tag exactly.

## When a check is wrong

The script encodes assumptions about this repo's conventions. If it produces a
false positive, prefer fixing the check over adding an exception to the docs — a
noisy audit gets ignored, which is worse than no audit. Each check is a small
self-contained block; the pattern is to narrow the match, not to suppress output.

## Scope

This verifies *claims about the system*. It does not judge whether prose is
well-written, whether a service is configured sensibly, or whether the
architecture is sound. Those need a human. Keep the script mechanical so its
output stays trustworthy.
