# Sablier

**Purpose**: Wake-on-demand scaling — stops idle services to save resources and wakes them automatically on the first incoming request via Traefik.

## How It Works

```
User visits service URL
        ↓
   Traefik receives request
        ↓
   Sablier middleware intercepts
        ↓
   Container stopped? → Start containers → Show loading page → Redirect when ready
   Container running? → Pass through immediately
        ↓
   Service idle > session duration → Sablier stops containers
```

Sablier runs as a Traefik plugin. Each managed service has a Sablier middleware label pointing to `http://sablier:10000`. When a request arrives for a stopped service, Sablier starts all containers in the group and serves a loading page (theme: `hacker-terminal`) until they're healthy.

## Configuration

| Setting         | Value                                  |
| --------------- | -------------------------------------- |
| **Image**       | `sablierapp/sablier:latest`            |
| **Port**        | 10000 (internal, proxy network)        |
| **Provider**    | Docker                                 |
| **Socket**      | `/var/run/docker.sock` (read-only)     |
| **Config file** | `/HOMELAB/services/sablier/config.yml` |
| **Restart**     | `unless-stopped` (always running)      |

## Dependencies

- **Networks**: `proxy` (external) — must be reachable by Traefik
- **Traefik plugin**: `sablier` v1.10.1 must be installed in Traefik
- **Docker socket**: read-only access to start/stop containers

## Managed Services

All groups are defined in `config.yml`. Session duration is set per-service via Traefik labels (default: `5m`).

| Group                 | Containers                                                                        | Session |
| --------------------- | --------------------------------------------------------------------------------- | ------- |
| `affine-stack`        | affine_server, affine_migration_job, affine_redis, affine_postgres                | 5m      |
| `chartdb-stack`       | chartdb                                                                           | 5m      |
| `drawdb-stack`        | drawdb                                                                            | 5m      |
| `excalidraw-stack`    | excalidraw                                                                        | 5m      |
| `glance-stack`        | glance                                                                            | 5m      |
| `it-tools-stack`      | it-tools                                                                          | 5m      |
| `linkwarden-stack`    | linkwarden, linkwarden-db, linkwarden-meilisearch                                 | 5m      |
| `lobe-chat-stack`     | lobe_chat, lobe_chat_db, lobe_chat_minio                                          | 5m      |
| `outline-stack`       | outline, outline-db, outline-redis                                                | 5m      |
| `paperless-ngx-stack` | paperless-ngx, paperless-db, paperless-redis, paperless-tika, paperless-gotenberg | 5m      |
| `paperless-gpt-stack` | paperless-gpt                                                                     | 5m      |
| `stirling-pdf-stack`  | stirling-pdf                                                                      | 5m      |

> **Not managed by Sablier**: OpenCloud's OnlyOffice (`opencloud-onlyoffice`) runs `always-on` (`restart: unless-stopped`). It must remain available for document editing via the collaboration service.

## Adding a Service to Sablier

**1. Add a group to `config.yml`:**
```yaml
- name: my-service-stack
  containers:
    - my-service
    - my-service-db   # include all containers that must wake together
```

**2. Add labels to the service's `docker-compose.yml`:**
```yaml
labels:
  - traefik.http.middlewares.my-service-sablier.plugin.sablier.sablierUrl=http://sablier:10000
  - traefik.http.middlewares.my-service-sablier.plugin.sablier.sessionDuration=5m
  - traefik.http.middlewares.my-service-sablier.plugin.sablier.group=my-service-stack
  - traefik.http.middlewares.my-service-sablier.plugin.sablier.dynamic.theme=hacker-terminal
  - traefik.docker.allownonrunning=true
  - traefik.http.routers.my-service.middlewares=my-service-sablier
  - sablier.enable=true
  - sablier.group=my-service-stack
```

**3. Change restart policy to `'no'`** so Docker doesn't fight Sablier's stop:
```yaml
restart: 'no'
```

**4. Update `start-all.sh`** — add the service to the `SABLIER_SERVICES` array so it starts in scaled-to-zero state.

## Deployment

```bash
# Start Sablier (must be running before managed services start)
cd /HOMELAB/services/sablier
docker compose up -d

# Verify it's reachable from Traefik's network
docker exec traefik wget -qO- http://sablier:10000/health
```

## Operations

```bash
# Check which groups/containers Sablier knows about
curl http://localhost:10000/api/v1/groups

# Manually wake a group
curl -X POST http://localhost:10000/api/v1/groups/glance-stack

# Check Sablier logs
docker logs sablier -f

# See current container states
docker ps --filter label=sablier.enable=true --format "table {{.Names}}\t{{.Status}}"
```

## Notes

- Sablier itself uses `restart: unless-stopped` — it must always be running
- Managed services use `restart: 'no'` — Sablier owns their lifecycle
- `traefik.docker.allownonrunning=true` is required so Traefik keeps the route active even when the container is stopped
- `start-all.sh` starts all services then stops Sablier-managed ones, so they begin in scaled-to-zero state on every boot
