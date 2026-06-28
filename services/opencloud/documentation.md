# OpenCloud

**Purpose**: Self-hosted cloud storage platform (ownCloud successor) with document collaboration via OnlyOffice

## Architecture

5 containers orchestrated via Docker Compose:

| Container | Image | Role |
|-----------|-------|------|
| `opencloud` | `opencloudeu/opencloud-rolling:latest` | Main application server |
| `opencloud-onlyoffice` | `onlyoffice/documentserver:latest` | Document editing (WOPI) |
| `collaboration` | `opencloudeu/opencloud-rolling:latest` | WOPI collaboration bridge |
| `opencloud-tika` | `apache/tika:latest-full` | Full-text search extraction |
| `opencloud-clamav` | `clamav/clamav:latest` | Antivirus scanning |

**Networks**: `proxy` (Traefik), `opencloud_internal` (isolated service communication)

## URLs

| Service | URL |
|---------|-----|
| OpenCloud | https://drive.alimunee.com |
| OnlyOffice | https://onlyoffice.alimunee.com |

## Storage

| Path | Purpose |
|------|---------|
| `/storage/data/opencloud/config` | OpenCloud config (incl. `opencloud.yaml` with secrets) |
| `/storage/data/opencloud/data` | User data (decomposed filesystem) |
| `/storage/data/opencloud/onlyoffice/data` | OnlyOffice data |
| `/storage/data/opencloud/onlyoffice/logs` | OnlyOffice logs |

## Authentication — Zitadel SSO

OpenCloud uses Zitadel for SSO via OIDC (PKCE flow).

**Zitadel app settings**:
- Application type: Native / SPA (PKCE, no client secret)
- Client ID: stored in `.env` as `OC_CLIENT_ID`
- Redirect URI: `https://drive.alimunee.com/oidc-callback.html`
- Post-logout redirect URI: `https://drive.alimunee.com`
- Scopes: `openid profile email`

**Auto-provisioning**: Users are created automatically on first login using the `preferred_username` and `email` claims from Zitadel.

## Admin Access

- **SSO user `ali`** — has Admin role, use for day-to-day admin tasks
- **Built-in `admin` account** — email `ali@rabeei.com`, password in `/storage/data/opencloud/config/opencloud.yaml` under `admin_password`. Enable basic auth via `PROXY_ENABLE_BASIC_AUTH: "true"` in docker-compose to use.

## Key Features Enabled

| Feature | Config |
|---------|--------|
| Full-text search | Apache Tika at `http://tika:9998` |
| Antivirus | ClamAV via Unix socket, max 100MB, `abort` on infection |
| Document editing | OnlyOffice via WOPI at `onlyoffice.alimunee.com` |
| Public shares | No password required (configurable) |

## OnlyOffice Integration

This is a **dedicated OnlyOffice instance** for OpenCloud.

Communication flow:
```
Browser → OnlyOffice (onlyoffice.alimunee.com)
       → Collaboration service (WOPI bridge, internal)
       → OpenCloud (drive.alimunee.com)
```

Config files:
- `config/onlyoffice/local.json` — JWT secret, IP filtering (only `collaboration` container allowed)
- `config/onlyoffice/entrypoint-override.sh` — startup script

## Web Apps / Extensions — intentionally NOT installed

No custom web extensions are installed, and the `./config/opencloud/apps` volume mount has been
**removed** from `docker-compose.yml`. OpenCloud uses its own built-in apps dir.

> **⚠️ Do not re-add web extensions (draw-io / json-viewer / maps / unzip).** They load via module
> federation and are **tightly coupled to the bundled web UI version**. The image is
> `opencloudeu/opencloud-rolling:latest` (auto-updated by arcane), so the web UI version drifts.
> A mismatch — too old (plain `js/<app>-*.js`) *or* too new (`remoteEntry-*.mjs` built for a newer
> web) — fails with `cannot load application ... not a valid module federation remote entry`, and
> because the mount masks the built-in apps dir, it breaks **all** app loading **including the
> OnlyOffice editor** (symptom: office files open to a loading skeleton that never finishes).
>
> History: stale Apr-2026 bundles broke OnlyOffice on the 7.2.0 upgrade (2026-06-29). Updating to
> the latest extension releases did NOT fix it (those target a newer web than the bundled 7.1.2),
> so the extensions were removed entirely. If you ever want them back, pin the opencloud image to a
> fixed tag first, then install the exact extension versions matching that release's web UI.
>
> Verify after any OpenCloud change in a **private window** (browsers cache the bundle and OnlyOffice
> installs a ServiceWorker on `onlyoffice.alimunee.com`).

## Management

```bash
# Start all services
cd /HOMELAB/services/opencloud && docker compose up -d

# View logs
docker logs opencloud --tail 50 -f

# Restart just the main service
docker compose restart opencloud

# Check antivirus database update
docker logs opencloud-clamav --tail 20
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Login fails / OIDC error | Check `OC_OIDC_ISSUER` matches Zitadel, verify redirect URIs in Zitadel app |
| "missing claim" on login | Zitadel isn't sending expected claim — check `PROXY_AUTOPROVISION_CLAIM_*` env vars |
| Permission denied on config | `/storage/data/opencloud/config` must be owned by `1000:1000`: `sudo chown -R 1000:1000 /storage/data/opencloud` |
| Reset config | Stop containers, wipe `/storage/data/opencloud/config/*` and `/storage/data/opencloud/data/*`, restart — will re-run `opencloud init` |
| ClamAV not ready | ClamAV downloads virus DB on startup (~300MB), can take several minutes |
| Large file upload fails via WebDAV (413) | Use the web UI which uses TUS chunked uploads; rclone WebDAV hits the body size limit |
