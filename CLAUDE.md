# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**RedRipper** is a single-node homelab running 39+ containerized services on Fedora Server with Docker Compose. The host is an AMD Threadripper 2920X / 32GB RAM / GTX 1070 with dual-tier Btrfs storage (1TB NVMe + 3.6TB HDD). Static IP: `192.168.1.2`.

## Repository Layout

- `services/<name>/` — Each service has its own directory with `docker-compose.yml`, `documentation.md`, and optionally `.env`
- `services/.env.global` — Shared environment variables across services
- `configs/` — System-level configuration (network, security, snapper, systemd timers, Docker daemon)
- `scripts/` — Operational scripts (`start-all.sh`, `flared`, storage monitors)
- `docs/docker/` — Docker infrastructure docs (numbered 00-12)
- `docs/system/` — System administration docs (numbered 01-09)

## Common Commands

```bash
# Deploy all services (infrastructure-first, then alphabetical)
/HOMELAB/scripts/start-all.sh
/HOMELAB/scripts/start-all.sh -e service1,service2  # exclude specific services

# Single service operations (always cd into service dir first)
cd /HOMELAB/services/<name> && docker compose up -d
cd /HOMELAB/services/<name> && docker compose down && docker compose up -d
docker compose -f /HOMELAB/services/<name>/docker-compose.yml logs -f

# Container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"

# Storage health
sudo btrfs fi usage /storage
watch -n 5 'df -h /storage && echo "---" && du -sh /storage/*'

# GPU monitoring (Jellyfin + Immich ML use the GTX 1070)
nvidia-smi
docker exec jellyfin nvidia-smi

# Notifications
curl -d "Test message" http://localhost:8888/system-alerts

# Deploy system configs
sudo /HOMELAB/configs/deploy-configs-fedora.sh

# Systemd timers (btrfs monitoring hourly, scrub weekly, kopia backup daily)
systemctl list-timers btrfs-* kopia-*
```

## Architecture

### Network Flow
```
Internet -> Cloudflare CDN/WAF -> Cloudflared Tunnel -> Traefik (reverse proxy) -> Services
                                                    OR
Tailscale VPN (redripper.taila7b279.ts.net) ---------> Services
```

### Docker Networks
- `proxy` — All web-facing services connect to this; Traefik routes traffic
- `db_network` — Shared database access
- Service-specific internal networks (e.g., `immich_internal`, `opencloud_internal`, `infisical_internal`) isolate sensitive stacks

### Startup Order (`start-all.sh`)
1. Infrastructure first: traefik, postfix, cloudflared, adguard
2. All remaining services alphabetically
3. Sablier-managed services are then stopped for wake-on-demand (affine, chartdb, drawdb, excalidraw, glance, it-tools, linkwarden, lobe-chat, outline, paperless-gpt, paperless-ngx, stirling-pdf)

### Key Infrastructure Services
- **Traefik v3.6** — Reverse proxy with Let's Encrypt SSL, Sablier plugin for wake-on-demand
- **Zitadel** — SSO/OIDC identity provider
- **Cloudflared** — Zero-trust tunnel (no port forwarding)
- **AdGuard Home** — DNS filtering (ports 53, 3333, 8989)
- **Postfix** — SMTP relay via Brevo upstream
- **ntfy** — Push notification server
- **Sablier** — Scales 13 low-traffic services to zero, wakes on HTTP request

### Storage Layout
- **NVMe (1TB)**: `/` (root, snapper), `/storage/data` (snapper), `/var/lib/docker`
- **HDD (3.6TB)**: `/storage/media`, `/storage/Immich` (snapper), `/storage/share` (snapper)
- **Backups**: Snapper snapshots (hourly/daily) + Kopia daily to AWS S3 Glacier

## Working with Services

Each service follows the same pattern: `services/<name>/docker-compose.yml` defines the stack. Credentials live in per-service `.env` files (gitignored). When adding or modifying a service:

- Attach to the `proxy` network if it needs Traefik routing
- Use Traefik labels for routing, SSL, and middleware (OIDC, Sablier, etc.)
- Use service-specific internal networks to isolate databases/caches from the proxy network
- GPU services need `runtime: nvidia` and device reservations in compose
- Update `services/<name>/documentation.md` with any operational notes

## Commit Style

Short lowercase messages describing the change: `fix SSO for android app`, `remove mail network`, `update docs`.
