---
name: add-service
description: Add a new containerized service to the RedRipper homelab, or remove an existing one, keeping the compose file, Traefik routing, Sablier set, startup script, and all six documentation touchpoints in agreement. Use this whenever the user wants to deploy, install, set up, add, or self-host a new service; asks to remove or decommission one; asks "how do I add X to the homelab"; or wants an existing bare `docker run` container adopted into the repo. Also use it when a service exists but is missing from the docs or the service index.
---

# Add a service to RedRipper

Adding a service is easy to start and easy to half-finish. The compose file is
the fun part; the cost is that a service is referenced from six places, and
missing one leaves a gap nobody notices for months. `vert` sat in the repo
running happily while being absent from the master service index — that is the
failure mode this skill exists to prevent.

## Gather these before writing anything

Guessing any of these produces a service that half-works:

- **Image and pinned tag.** Most of this repo runs `:latest`; pin only when the
  service is version-sensitive, and if you pin, the version must also appear in
  its `documentation.md`.
- **Internal port** the container actually listens on.
- **Domain** — `<name>.alimunee.com`. Check it is free in *both* places, because
  they drift independently:
  ```bash
  grep -rn 'Host(`<name>' services/   # is a Traefik router already claiming it?
  flared list | grep '<name>'         # is the tunnel already serving it?
  ```
- **Persistence.** Config and databases go on `/storage/data/<service>/`; bulk
  media on `/storage/media/`. The distinction matters — only `/storage/data` is
  backed up off-site.
- **Traffic shape.** Constant traffic means always-on; occasional use means
  Sablier. Roughly a third of this homelab is Sablier-managed.
- **Dependencies.** Its own database? SSO through Zitadel? GPU?

## Write the compose file

Read `references/patterns.md` and copy the pattern that fits: always-on,
Sablier wake-on-demand, with-database, or GPU. It documents the conventions that
are invisible until violated — particularly that Sablier services need
`restart: 'no'`, `traefik.docker.allownonrunning=true`, and group labels on
*every* container in the stack.

Put the file at `services/<name>/compose.yml`. Secrets belong in a per-service
`.env` (gitignored) referenced as `${VAR}` — this repository is public.

## Update every touchpoint

This is the part that gets dropped. Work through all of it:

1. **`services/<name>/compose.yml`** — the stack.
2. **`services/<name>/documentation.md`** — start from
   `assets/documentation-template.md`. Every service in this repo has one; the
   audit treats a missing file as an error.
3. **`docs/docker/00_README.md`** — a row in the Complete Service Reference
   table. Links are relative to `docs/docker/`, so they need `../../services/...`
   — one `../` resolves to `docs/services/` and is silently broken.
4. **The matching category doc** — a bullet in the relevant
   `docs/docker/0[3-9]|10_*.md` with a link to the service's documentation.
5. **`README.md`** — bump the service count (it appears in three places) and add
   the service to its category row.
6. **`CLAUDE.md` and `AGENTS.md`** — bump the count in the opening paragraph.
   These two files are maintained byte-identical: edit `CLAUDE.md`, then
   `cp CLAUDE.md AGENTS.md`.

If the service is Sablier-managed, two more:

7. **`scripts/start-all.sh`** — add it to `SABLIER_SERVICES`.
8. **`CLAUDE.md`/`AGENTS.md`** — add it to the wake-on-demand enumeration and
   check the stated count still matches.

Display names in the index may differ from directory names (`Vert.sh` links to
`services/vert/`). That is fine — the link target is what identifies the service.

## Publish the hostname through the tunnel

Traefik labels alone do **not** make a service reachable from the internet.
There is no port forwarding here — traffic arrives through the Cloudflare tunnel,
and the tunnel only forwards hostnames listed in its ingress config. A service
with perfect labels and no tunnel entry works on the LAN and 404s everywhere else.

`flared` handles this. It writes the tunnel ingress route **and** the proxied
CNAME record in one step:

```bash
flared add <name>            # -> <name>.alimunee.com via http://traefik
flared list | grep <name>    # confirm
```

The default target is `http://traefik`, which is what you want for anything
Traefik routes. Pass an explicit target only when bypassing Traefik entirely —
for example a service on the host rather than in Docker:

```bash
flared add cockpit 192.168.1.2:9090 https
```

`flared` reads its credentials from `services/cloudflared/.env`. It refuses to
add a hostname that already exists, so a failure here usually means the name is
taken — pick another rather than forcing it.

## Deploy and verify

```bash
sudo mkdir -p /storage/data/<name>/config
sudo chown -R 1000:1000 /storage/data/<name>/
cd /HOMELAB/services/<name> && docker compose up -d
docker compose ps
```

Then confirm the routing actually took effect, rather than assuming it did:

```bash
docker logs <name> --tail 30
curl -sI https://<name>.alimunee.com | head -3
```

For a Sablier service, the meaningful test is that it *wakes*: stop it, then
request the domain and watch it come back.

```bash
docker compose stop
curl -s -o /dev/null -w '%{http_code}\n' https://<name>.alimunee.com
docker ps --filter name=<name>
```

For a GPU service, `docker exec <name> nvidia-smi` should show the card.

## Finish with the audit

```bash
bash .claude/skills/verify-docs/scripts/audit.sh /HOMELAB
```

This is the cheapest way to prove nothing was missed — it checks index
membership, category coverage, counts, the Sablier set, and the restart-policy
trap. Adding a service should leave the audit clean.

## Removing a service

The same list in reverse, and the order matters: stop the containers first, then
remove the routing, then the docs, so nothing points at a dead endpoint.

```bash
cd /HOMELAB/services/<name> && docker compose down
flared delete <name>
```

Do not skip `flared delete`. A tunnel route left behind keeps a public hostname
resolving to a service that no longer exists, and the entry outlives the repo
directory — the audit currently finds a couple of dozen such orphans from
services decommissioned long ago. Note that `flared delete` removes the DNS
record as well, so it is outward-facing and not trivially reversible: confirm the
hostname is genuinely retired before running it.

Decide deliberately what happens to `/storage/data/<name>/` — deleting it is
irreversible and Snapper snapshots age out. Leaving the data while removing the
service is a reasonable default; say so explicitly rather than silently.

Then remove the service directory and every reference from the six touchpoints
above, and re-run the audit — it will flag a stale index row pointing at a
directory that no longer exists.

## Adopting an unmanaged container

Occasionally something is running from a bare `docker run` and has no directory
here (the audit reports these). Adopting it means reconstructing the compose file
from the live container before anything else:

```bash
docker inspect <name> --format '{{json .Config}}'   # image, env, cmd
docker inspect <name> --format '{{json .Mounts}}'   # volumes to preserve
```

Write the compose file to match what is actually running, `docker compose up -d`
to take ownership, verify the service still behaves, and only then work through
the documentation touchpoints. Confirm with the user before recreating a
container that holds live data.
