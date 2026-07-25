# RedRipper compose patterns

Copy the pattern that matches the service's shape, then adapt. These are
distilled from the 42 services already in the repo — deviating from them is
usually a bug, not a style choice.

## Conventions that apply to every service

| Convention | Value | Why |
|---|---|---|
| Container name | matches the directory name | `docker logs <name>` should just work |
| Timezone mount | `/etc/localtime:/etc/localtime:ro` | logs and schedules match the host |
| DNS | `8.8.8.8`, `1.1.1.1` | container DNS is unreliable behind the tunnel |
| Persistent data | `/storage/data/<service>/...` | NVMe tier, covered by Snapper + Kopia |
| Bulk media | `/storage/media/...` | HDD tier, deliberately *not* backed up off-site |
| External network | `proxy` (declared `external: true`) | Traefik discovers services here |
| Router name | may differ from service name | e.g. `linkwarden` routes as `bookmarks` |

Domains are `<something>.alimunee.com`. Pick a short noun that reads well in a
browser bar — the repo favours `tools`, `draw`, `photos`, `convert` over product
names.

## Pattern A — always-on, single container

For infrastructure and anything that must answer instantly.

```yaml
services:
  myservice:
    image: vendor/myservice:latest
    container_name: myservice
    restart: unless-stopped
    environment:
    - TZ=Asia/Kuala_Lumpur
    volumes:
    - /storage/data/myservice/config:/config
    - /etc/localtime:/etc/localtime:ro
    dns:
    - 8.8.8.8
    - 1.1.1.1
    networks:
    - proxy
    labels:
    - traefik.enable=true
    - traefik.http.routers.myservice.rule=Host(`myservice.alimunee.com`)
    - traefik.http.services.myservice.loadbalancer.server.port=8080
    - traefik.docker.network=proxy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 128M
networks:
  proxy:
    external: true
```

## Pattern B — Sablier wake-on-demand

For low-traffic services that should idle at zero and wake on first request.
This pattern has three parts that must all be present, and it fails silently if
any is missing.

```yaml
services:
  myservice:
    image: vendor/myservice:latest
    container_name: myservice
    restart: 'no'                    # <-- critical, see below
    networks:
    - proxy
    labels:
    - traefik.enable=true
    - traefik.http.routers.myservice.rule=Host(`myservice.alimunee.com`)
    - traefik.http.services.myservice.loadbalancer.server.port=80
    - traefik.docker.network=proxy
    - traefik.http.middlewares.myservice-sablier.plugin.sablier.sablierUrl=http://sablier:10000
    - traefik.http.middlewares.myservice-sablier.plugin.sablier.sessionDuration=5m
    - traefik.http.middlewares.myservice-sablier.plugin.sablier.group=myservice-stack
    - traefik.http.middlewares.myservice-sablier.plugin.sablier.dynamic.theme=hacker-terminal
    - traefik.docker.allownonrunning=true
    - traefik.http.routers.myservice.middlewares=myservice-sablier
    - sablier.enable=true
    - sablier.group=myservice-stack
```

Three things earn special attention because each one breaks the feature quietly:

**`restart: 'no'` is mandatory.** `start-all.sh` stops these containers on
purpose. With `unless-stopped` or `always`, Docker immediately restarts them and
the service never actually scales to zero — it just looks like it works while
consuming memory forever. `verify-docs` checks for exactly this.

**`traefik.docker.allownonrunning=true`.** Traefik drops routes for stopped
containers by default, so without this the router disappears the moment the
service scales down and the wake request 404s instead of waking anything.

**Every container in the stack needs the `sablier.enable` and `sablier.group`
labels** — including databases and search sidecars. Sablier wakes a *group*; if
the database lacks the label, the app wakes without its database.

After writing the compose file, add the service to `SABLIER_SERVICES` in
`scripts/start-all.sh` and to the enumeration in `CLAUDE.md`/`AGENTS.md`.

## Pattern C — service with its own database

Isolate the database on a private network so it is unreachable from `proxy`.

```yaml
services:
  myservice:
    image: vendor/myservice:latest
    container_name: myservice
    restart: unless-stopped
    env_file:
    - .env
    environment:
    - DATABASE_URL=postgresql://myservice:${DB_PASSWORD}@myservice-db:5432/myservice
    networks:
    - proxy
    - myservice_internal
    depends_on:
    - myservice-db

  myservice-db:
    image: postgres:17-alpine
    container_name: myservice-db
    restart: unless-stopped
    env_file:
    - .env
    environment:
    - POSTGRES_DB=myservice
    - POSTGRES_USER=myservice
    - POSTGRES_PASSWORD=${DB_PASSWORD}
    - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
    - /storage/data/myservice/db:/var/lib/postgresql/data
    networks:
    - myservice_internal
    - db_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d myservice -U myservice"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

networks:
  proxy:
    external: true
  myservice_internal:
    name: myservice_internal
    driver: bridge
  db_network:
    external: true
    name: db_network
```

The application joins both `proxy` and `myservice_internal`; the database joins
`myservice_internal` and `db_network` but never `proxy`. That is what keeps the
database off the routed network.

Secrets go in a per-service `.env` (gitignored) and are referenced as
`${VAR}`. Never inline a credential in `compose.yml` — it is a public repo.

## Pattern D — GPU service

The GTX 1070 is shared between Jellyfin (transcoding) and Immich (ML inference).

```yaml
    environment:
    - NVIDIA_VISIBLE_DEVICES=all
    - NVIDIA_DRIVER_CAPABILITIES=all
    deploy:
      resources:
        reservations:
          devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
```

Verify with `docker exec <name> nvidia-smi` after starting. Because the card is
shared, check `nvidia-smi` on the host before adding a third consumer.

## SSO via Zitadel

Services that support OIDC authenticate against Zitadel:

```yaml
    - OIDC_ISSUER=https://zitadel.alimunee.com
    - OIDC_CLIENT_ID=${ZITADEL_CLIENT_ID}
    - OIDC_CLIENT_SECRET=${ZITADEL_CLIENT_SECRET}
```

Create the application in the Zitadel console first, then put the credentials in
the service's `.env`. Exact variable names vary by product — check upstream docs.
