# Arcane - Docker Management (SvelteKit)

Modern, web-based UI for managing Docker containers, images, volumes, and networks. Deployed behind Traefik on the `proxy` network.

## Service

- **Image**: `ghcr.io/ofkm/arcane:latest`
- **URL**: https://manage.alimunee.com
- **Internal Port**: 3552
- **Purpose**: Manage Docker with a clean, fast UI

## Access

- Navigate to: `https://manage.alimunee.com`
- Default login (change immediately):
  - Username: `arcane`
  - Password: `arcane-admin`

## Dependencies

- Network: `proxy` (external)
- Reverse proxy: Traefik v3 (Cloudflare tunnel provides TLS)
- Volumes:
  - `/var/run/docker.sock`
  - `/storage/data/arcane:/app/data`
  - `/HOMELAB/services:/app/stacks:ro`

## Configuration

Environment variables (.env):

| Variable              | Description                         | Default    | Required |
| --------------------- | ----------------------------------- | ---------- | -------- |
| APP_ENV               | Application environment             | production | Yes      |
| PUBLIC_SESSION_SECRET | Frontend session encryption secret  | -          | Yes      |
| ENCRYPTION_KEY        | Backend encryption key (>=32 bytes) | -          | Yes      |
| PUID                  | File permission user ID             | 1000       | No       |
| PGID                  | File permission group ID            | 1000       | No       |

## Setup

1) Prepare data directory
```bash
sudo mkdir -p /storage/data/arcane
sudo chown ali:ali /storage/data/arcane
```

2) Create secrets
```bash
cd /HOMELAB/services/arcane
echo SESSION_SECRET="base64:$(openssl rand -base64 32)" > .env
echo ENCRYPTION_KEY="base64:$(openssl rand -base64 32)" >> .env
```

3) Deploy
```bash
docker compose up -d
```

4) Verify
```bash
docker ps | grep arcane
docker logs arcane --tail=50
docker exec arcane curl -sf http://localhost:3552/ | head -c 100
```

## Traefik

Compose labels (already set):

- `traefik.enable=true`
- `traefik.http.routers.arcane.rule=Host(\`manage.alimunee.com\`)`
- `traefik.http.services.arcane.loadbalancer.server.port=3552`
- `traefik.docker.network=proxy`

Healthcheck: `curl -f http://localhost:3552/`

## Monitoring

- Uptime Kuma: add `https://manage.alimunee.com` (HTTP(s), 60s)
- Watchtower: `com.centurylinklabs.watchtower.enable=true`
- Optional ntfy notifications per `docs/docker/10_monitoring-management.md`

## Troubleshooting

- Permissions: ensure `/var/run/docker.sock` is readable by container user
- Secrets: `SESSION_SECRET` and `ENCRYPTION_KEY` must be present; key >=32 bytes
- Routing: container must join `proxy` network; check Traefik logs for router `arcane`
- Health: `docker exec arcane curl -f http://localhost:3552/`

## Notes

- Read-only mount of `/HOMELAB/services` enables viewing existing stacks
- TLS is terminated by Cloudflare; do not add explicit Traefik TLS labels
