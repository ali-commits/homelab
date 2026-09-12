# Tuwunel + Element — Self-hosted Matrix messaging

## Purpose

Private, end-to-end encrypted chat for family and friends at `element.alimunee.com`,
with accounts on a homeserver this house owns (`@you:alimunee.com`). It replaces
nothing — there was no chat service in the homelab before this.

The point is reachability: friends have no Tailscale and never will, so the whole
stack is reachable from the open internet through the existing Cloudflare Tunnel.
Messaging is HTTP + WebSocket, which the tunnel carries natively. (Audio/video
media is UDP and the tunnel cannot carry it, so calls are deliberately out of
scope — see [Integration](#integration).)

Two containers, one functional unit:

- **tuwunel** — the Matrix homeserver. Single Rust binary, no Postgres, no
  separate auth service. Speaks native OIDC, so Zitadel can broker logins later.
- **element-web** — the Element client, served as static files. Friends use it in
  a browser; mobile users install the Element app and point it at this server.

## Configuration

### Environment Variables

All configuration is environment-based; there is no `tuwunel.toml`. `[global]`
keys map to `TUWUNEL_<KEY>`, and nested tables use a `__` split
(`[global.well_known] server` → `TUWUNEL_WELL_KNOWN__SERVER`).

| Variable | Value | Why it is set |
| --- | --- | --- |
| `TUWUNEL_ADDRESS` | `0.0.0.0` | The default is loopback-only. Traefik is a *different container*, so the server would be unreachable and the tunnel would 502. |
| `TUWUNEL_PORT` | `8008` | Internal only; nothing is published to the host. |
| `TUWUNEL_DATABASE_PATH` | `/var/lib/tuwunel` | Mounted from `/storage/data/tuwunel/db` (backed up). |
| `TUWUNEL_SERVER_NAME` | `${MATRIX_SERVER_NAME}` | **Permanent.** Built into every user ID; changing it needs a database wipe. |
| `TUWUNEL_ALLOW_FEDERATION` | `false` | Private server. Nothing is shared with the wider Matrix network. |
| `TUWUNEL_ALLOW_REGISTRATION` | `true` | Signup exists, but only against the token below. |
| `TUWUNEL_REGISTRATION_TOKEN` | `${REGISTRATION_TOKEN}` | The invite secret. With a token set, registration *requires* it; there is no separate "require token" flag. |
| `TUWUNEL_WELL_KNOWN__CLIENT` | `https://matrix.alimunee.com` | Makes `alimunee.com/.well-known/matrix/client` answer, so typing `alimunee.com` in Element finds the server. |
| `TUWUNEL_WELL_KNOWN__SERVER` | `matrix.alimunee.com:443` | The federation-delegation answer for the same file pair. |
| `TUWUNEL_STORAGE_PROVIDER__MEDIA__LOCAL__BASE_PATH` | `/media` | Moves attachments off the backed-up database. Verified: uploads land in `/storage/media/tuwunel/media/`, and the DB directory holds only RocksDB files. |
| `TUWUNEL_ROCKSDB_ALLOW_FALLOCATE` | `false` | `database_path` is btrfs (Copy-on-Write). Without this, Tuwunel logs a warning on every boot: fallocate cannot reserve space on CoW and can pin far more disk than the write-ahead logs hold. |
| `TUWUNEL_MAX_REQUEST_SIZE` | `52428800` | 50 MiB, up from the 24 MiB default, so a phone video actually sends. |
| `TUWUNEL_NEW_USER_DISPLAYNAME_SUFFIX` | *empty* | Upstream appends a heart to new display names; empty keeps names clean. |
| `MATRIX_SERVER_NAME`, `REGISTRATION_TOKEN` | — | Live in `.env` (mode 600, gitignored). `.env.template` holds placeholders. |

Do **not** add a `curl` healthcheck. The image contains only the binary, `tini` and
CA certificates — there is no shell and no `curl` — and it already ships
`HEALTHCHECK CMD tuwunel --health-check`, which reads the config from the
environment, opens the listeners and requests `/_tuwunel/server_version`.

`stop_grace_period: 30m` is load-bearing: a first boot after an upgrade can run a
database migration that must not be interrupted, and Compose's 10-second default
would kill the server mid-migration.

### Ports

| Container | Internal | Host | Notes |
| --- | --- | --- | --- |
| tuwunel | 8008 | — | Reached through Traefik on the `proxy` network. |
| element-web | 80 | — | Reached through Traefik on the `proxy` network. |

No host ports are published, so neither service is exposed on the LAN directly.

### Domains

| Domain | Target | Notes |
| --- | --- | --- |
| `matrix.alimunee.com` | tuwunel:8008 | The homeserver API and client endpoint. |
| `element.alimunee.com` | element-web:80 | The web client. |
| `alimunee.com` (`/.well-known/matrix/*` only) | tuwunel:8008 | Delegation. A high-priority Traefik router claims only the `/.well-known/matrix` prefix; the rest of the root domain stays a 404, exactly as it was before this service. |

## Dependencies

- Traefik (`proxy` network) for routing.
- Cloudflared tunnel for public HTTPS (routes added with `./scripts/flared add`).
- Optionally Zitadel, issuer `https://zitadel.alimunee.com`, for OIDC login.
- For Android push: the existing ntfy service.

## Setup

### 1. Create Storage Directories

```bash
sudo mkdir -p /storage/data/tuwunel/db /storage/media/tuwunel/media
sudo chown -R 1000:1000 /storage/data/tuwunel /storage/media/tuwunel
```

The database must stay on the backed-up tier; media deliberately does not.

### 2. Generate The Invite Token

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(18))"
```

Put it in `.env` as `REGISTRATION_TOKEN=`, alongside `MATRIX_SERVER_NAME=`.

### 3. Deploy

```bash
cd /HOMELAB/services/tuwunel
docker compose create && docker compose start
docker logs tuwunel | tail        # expect: server_name=... Listening on ["tcp:0.0.0.0:8008"]
```

### 4. Publish The Hostnames

```bash
cd /HOMELAB
./scripts/flared add matrix
./scripts/flared add element
```

### 5. Create The Admin Account

**The first registration is granted server admin**, so register your own account
before sharing the invite token with anyone. Verification is a two-step
`m.login.registration_token` flow — first call to learn the session, second to
complete it:

```bash
# 1. ask what the server wants
curl -sS -X POST https://matrix.alimunee.com/_matrix/client/v3/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"ali","password":"<password>"}'
# -> {"flows":[{"stages":["m.login.registration_token"]}],"session":"..."}

# 2. complete it with that session and the token from .env
curl -sS -X POST https://matrix.alimunee.com/_matrix/client/v3/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"ali","password":"<password>",
       "auth":{"type":"m.login.registration_token","token":"<token>","session":"<session>"}}'
```

Admin rights are confirmed by an endpoint that refuses non-admins:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' \
  -H "Authorization: Bearer <access_token>" \
  'https://matrix.alimunee.com/_synapse/admin/v2/users?from=0&limit=3'   # 200 = admin, 403 = not
```

### 6. Onboard Friends

Friends open `https://element.alimunee.com`, choose *Create account*, and enter the
`REGISTRATION_TOKEN` when the client asks for the registration token. They become
normal (non-admin) users — verified: a token-registered second account gets `403`
from the admin API.

Once everyone is in, close the door: set `TUWUNEL_ALLOW_REGISTRATION=false`, restart,
and rotate the token.

## Usage

- **Web:** <https://element.alimunee.com> — sign in with your Matrix ID and password.
- **Mobile:** install Element (or Element X), pick *Edit* next to the homeserver
  field and enter `alimunee.com`; the client follows the `.well-known` file.
- **E2EE:** rooms are encrypted by default. Element will offer to set up Secure
  Backup on first login — **save the recovery key**. Losing it means losing the
  ability to read old messages; there is no server-side copy of the decryption keys.
- **Admin room:** the admin account is a member of an auto-created admins room and
  cannot leave it while it is the last admin. Admin commands run from there.
- **Notifications:** Android works through UnifiedPush (the homelab already runs
  ntfy) — install the ntfy app as the distributor. iOS notifications go through
  Apple's APNs via Element's push gateway; that leg cannot be self-hosted because
  APNs requires the app's own signing key.

## Integration

- **Delegation.** `server_name` is `alimunee.com`, not the hostname serving the
  API, so user IDs stay short and the homeserver can move later without changing
  anyone's identity. This works only because the root domain publishes
  `/.well-known/matrix/client` and `/server`.
- **Cloudflare.** Cloudflare fronts the API. One quirk worth knowing: the
  `Python-urllib/3.x` user agent is blocked by a browser-integrity rule (HTTP 403,
  Cloudflare error 1010) — on this hostname *and* on `git.alimunee.com`, so it
  predates this service. Real clients are unaffected: Element X iOS, Element X
  Android, Element Web and `curl` user agents all get `200`. Use `curl` when
  testing the API by hand.
- **CORS.** The homeserver answers `access-control-allow-origin: *`, which is what
  lets Element on `element.alimunee.com` talk to `matrix.alimunee.com`.
- **Zitadel SSO.** Tuwunel supports an upstream OIDC provider
  (`issuer_url`, `client_id`, `client_secret_file`, callback
  `/_matrix/client/unstable/login/sso/callback/<client_id>`), so the admin login can
  be moved to Zitadel without disturbing friends' password accounts. Not yet wired.
- **Bridges.** mautrix bridges (Telegram, WhatsApp, Signal) can attach to this
  homeserver later, which pairs with the existing `tlgrm` and `wacli` tooling.
- **Video calling.** Deliberately out of scope. WebRTC media is UDP; the Cloudflare
  Tunnel carries HTTP/WebSocket only, and friends have no Tailscale, so a call
  needs a directly reachable media server (port-forwarded Jitsi or a small VPS).
  Tuwunel can advertise such a transport later through
  `[global.well_known] rtc_transports`.

## Troubleshooting

### `502` from the tunnel, but the container is healthy

The default `TUWUNEL_ADDRESS` binds loopback only, inside a container that means
nothing else can reach it. It must be `0.0.0.0`.

### Container reports unhealthy even though it is serving

Something added a `curl` healthcheck. The image has no shell and no `curl`; the
built-in `tuwunel --health-check` is the only one that can run.

### `HTTP 403` with Cloudflare `error code: 1010` when testing with a script

A browser-integrity rule is rejecting the script's user agent, not a Matrix error.
Send a normal `User-Agent` (or use `curl`). Real clients are unaffected.

### Uploads are filling the backed-up volume

Check the media provider actually took effect — `TUWUNEL_STORAGE_PROVIDER__MEDIA__LOCAL__BASE_PATH`
must point at `/media`, and uploads must appear under `/storage/media/tuwunel/media/`.
The boot log line `Connected to storage provider name=media` alone does not prove
the path; a real upload does.

### Warning: `database_path is on a Copy-on-Write filesystem`

RocksDB cannot preallocate write-ahead logs on btrfs. Set
`TUWUNEL_ROCKSDB_ALLOW_FALLOCATE=false`.

### A friend cannot register

The token is either wrong, rotated, or `TUWUNEL_ALLOW_REGISTRATION` was set to
`false`. Registration is closed by design once everyone has joined.

### Push notifications never arrive on iOS

Expected on a self-hosted server without a gateway signed for APNs. Android
(ntfy/UnifiedPush) is fully self-hostable; iOS is not.

## Backup

### Data to Backup

| Path | Contents | Backed up? |
| --- | --- | --- |
| `/storage/data/tuwunel/db/` | RocksDB database — accounts, rooms, message history, state, and the server's identity | Yes (Kopia → B2 `redripper`, via the `/storage/data` scope) |
| `/storage/data/tuwunel/.env` | Server name and invite token | Yes (same scope) |
| `/storage/data/tuwunel/.credentials` | Admin password and invite token in plain text, mode 600 — the copy to read when handing out invites; delete it once you have them stored somewhere else | Yes (same scope) |
| `/storage/media/tuwunel/media/` | Attachments, images, video | **No** — deliberately excluded to keep backups small |

`/HOMELAB/services/tuwunel/` is in git; `.env` is not.

### Restore Process

1. Restore `/storage/data/tuwunel/db/` from the Kopia snapshot.
2. Recreate `.env` with the **same `MATRIX_SERVER_NAME`** — a different value
   against a restored database produces mismatched user IDs and a broken server.
3. `docker compose create && docker compose start` from
   `/HOMELAB/services/tuwunel/`, and confirm `server_name=` in the boot log.
4. Restore `/storage/media/tuwunel/media/` if you have a copy — message history
   returns without it, but attachments show as unavailable.
5. Re-publish the hostnames with `./scripts/flared add matrix` and
   `./scripts/flared add element` if the tunnel route was lost.

Members' existing sessions keep working after a restore, but E2EE history still
depends on each user's own recovery key — the server never holds it.
