---
name: triage-service
description: Diagnose a broken, unreachable, crash-looping, or misbehaving service in the RedRipper homelab, using a known catalogue of misleading symptoms whose obvious cause is wrong. Use this whenever the user says a service is down, broken, not loading, 502/503/404, stuck on a loading screen, restarting, unhealthy, or "everything is down"; when a container crash-loops; after a reboot when services do not come back; or when they ask why they cannot reach a domain. Prefer this over ad-hoc docker commands, because several failures in this homelab report a cause that is not the real one.
---

# Triage a RedRipper service

Most of this homelab fails in ways where the error message names the wrong
culprit. The generic loop — check logs, restart, hope — has repeatedly cost hours
here because the log line that looks like the problem was a downstream symptom.
So: gather state first, then check the symptom against the catalogue below before
forming a theory.

## Gather state first

```bash
bash .claude/skills/triage-service/scripts/state.sh <service>
```

Read-only, safe to run before you understand anything. It reports the service
definition, Sablier membership, per-container status with restart counts and
health, recent logs, network attachment, Traefik state, who owns port 443, and
disk pressure.

## Before anything else: is it actually broken?

**13 services are stopped on purpose.** Sablier scales them to zero and Traefik
wakes them on the first HTTP request. A stopped `excalidraw` container is the
system working correctly. The script says `MANAGED` when this applies.

The right test for these is whether the service *wakes*, not whether it is
running:

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://<domain>.alimunee.com
docker ps --filter name=<service>
```

Starting it by hand "fixes" nothing and hides the actual question, which is
whether waking works. If a Sablier service genuinely will not wake, suspect the
three-part label contract — `restart: 'no'`, `traefik.docker.allownonrunning=true`,
and `sablier.group` on *every* container in the stack. A stack whose database
lacks the group label wakes the app without its database.

## Symptom catalogue

These are failures already diagnosed the hard way in this homelab. Check here
before trusting the error text.

### Every service is down at once after a reboot

Almost never 42 separate faults. Check, in order:

1. **Port 443 owner.** `tailscale serve` can claim `:443` before Traefik binds
   it. Traefik then fails to start and everything appears dead while each
   container looks healthy. `sudo tailscale serve --https=443 off` releases it.
2. **Traefik itself.** If Traefik is down, every routed service is unreachable
   regardless of its own health. Fix Traefik first; re-triaging individual
   services before that wastes effort.
3. **Sablier services do not auto-start after a reboot.** They stay stopped until
   requested — expected, not a fault.
4. **Disk pressure.** A full NVMe presents as unrelated services failing to write.

### OpenCloud crash-loops citing NATS

The NATS connection error is a **red herring**. The real cause is the sharing
service missing `OC_SERVICE_ACCOUNT_ID` / `OC_SERVICE_ACCOUNT_SECRET`. Chasing
the NATS message leads nowhere.

### OnlyOffice opens to a loading skeleton that never finishes

Not an OnlyOffice fault. Stale OpenCloud **web extensions** break module
federation after a version upgrade. The extensions were removed deliberately —
see `services/opencloud/documentation.md`, which warns against re-adding
`draw-io` / `json-viewer` / `maps` / `unzip`. Updating them to newer releases
does *not* fix it, because those target a newer web bundle than the one shipped.

Always verify in a **private window**: browsers cache the bundle and OnlyOffice
installs a ServiceWorker on its domain, so a stale success or failure persists.

### Zitadel feature flags that silently do nothing

The `/v2beta` features API accepts a `loginV2` payload and ignores it, returning
success. Use the **`/v2`** endpoint. Full procedure, including the PAT elevation
dance, is in `services/zitadel/LOGIN_V2_TROUBLESHOOTING.md`.

### Reachable on the LAN, dead from the internet

There is no port forwarding here — external traffic arrives through the
Cloudflare tunnel, and the tunnel only carries hostnames listed in its ingress
config. A hostname missing from that list fails *before* anything in this
homelab is consulted, so Traefik, the network, and the container all look
perfectly healthy while the site is down.

```bash
flared list | grep <name>
```

If the hostname is absent, that is the whole explanation: `flared add <name>`
adds both the ingress route and the proxied CNAME. The state script checks every
hostname the service routes, not just the first — a stack like `opencloud` serves
two, and one can be published while the other is not.

A hostname appearing **twice** in `flared list` is dead config rather than a
fault: the first ingress match wins and later duplicates are never consulted.
Worth cleaning up, but it is not what is breaking the service.

Conversely, a hostname in the tunnel with no Traefik router is usually a
decommissioned service whose route outlived it. Removing it with
`flared delete <name>` also deletes the DNS record, so confirm the name is
genuinely retired first.

### A service 404s or 502s but the container is healthy

Routing, not the application:

- Is the container on the `proxy` network? A service Traefik cannot see is not
  routed. The state script prints network attachment.
- Do the Traefik labels name the right internal port? The label must match the
  port *inside* the container, not a published host port.
- Is the router rule's host actually the domain being requested?
- For a Sablier service, is `traefik.docker.allownonrunning=true` present? Without
  it, Traefik drops the route the moment the container stops, so the waking
  request 404s instead of waking anything.

### High restart count with a "running" status

`restarts=523` on a container reporting `running` means it is crash-looping and
you happened to catch it up. Treat a large restart count as a failure even when
the current status looks fine — read the logs from the *previous* run:

```bash
docker logs <container> --tail 100
docker inspect <container> --format '{{.State.ExitCode}} {{.RestartCount}}'
```

### Storage-related weirdness

Btrfs plus Docker copy-on-write has caused NVMe exhaustion here before (see
`docs/incidents/2026-03-20_nvme-storage-exhaustion.md`). Symptoms are diffuse:
unrelated services failing to write, databases refusing connections. Check
`df -h /` and `sudo btrfs fi usage /` before assuming an application bug.

## Working the problem

When the symptom is not in the catalogue, narrow by layer — each step rules out
everything below it:

1. **Cloudflare tunnel** — is the hostname in `flared list`? If not, nothing
   below this line matters for external access.
2. **Host** — disk, memory, port 443 ownership.
3. **Traefik** — running, and is this service's router registered?
4. **Network** — is the container attached to `proxy`? Is its database reachable
   on the internal network but *not* on `proxy`?
5. **Container** — status, restart count, health check, exit code.
6. **Application** — logs, configuration, credentials.

The tunnel sits at the top deliberately. It is the layer people forget, and it is
the one where every lower-level check reports "healthy" while the service is
unreachable — the most expensive way to be misled.

Prefer reversible probes over changes. Reading logs, inspecting, and curling cost
nothing; recreating a container can destroy the evidence that explains the fault.
Establish the cause before changing configuration, and change one thing at a
time — this repo is a single node with no staging, so a speculative fix that
half-works leaves the system in a state nobody can reason about.

## After the fix

If the cause was non-obvious — especially if the error message pointed somewhere
misleading — record it where the next person will collide with it: the service's
`documentation.md` for a service-specific trap, or
`docs/incidents/` with a row in its index table for anything that caused an
outage. A red herring documented once saves the same hour repeatedly, which is
exactly how the entries above came to exist.
