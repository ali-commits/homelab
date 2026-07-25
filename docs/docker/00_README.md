# Docker Infrastructure Overview

## Quick Status Dashboard
- **Total Services**: 42 deployed and running (13 managed via Sablier wake-on-demand)
- **Last Updated**: July 25, 2026
- **Infrastructure Health**: ✅ All systems operational

## Service Categories & Quick Access

| Category                         | Count | Key Services                                                             | Documentation                         |
| -------------------------------- | ----- | ------------------------------------------------------------------------ | ------------------------------------- |
| **Docker Networks**              | -     | Network topology & configuration                                         | [📖](01_docker-networks.md)            |
| **Storage & Volumes**            | -     | Filesystem, volumes, database storage                                    | [📖](02_storage-volumes.md)            |
| **Core Infrastructure**          | 3     | Traefik, Cloudflared, AdGuard                                            | [📖](03_core-infrastructure.md)        |
| **Authentication**               | 1     | Zitadel                                                                  | [📖](04_authentication.md)             |
| **AI/ML Services**               | 4     | Lobe Chat, Karakeep, Paperless-GPT, Immich ML                            | [📖](05_ai-ml-services.md)             |
| **Notifications & SMTP**         | 2     | ntfy, Postfix                                                            | [📖](06_notifications-smtp.md)         |
| **Data Services**                | 10    | Immich, Karakeep, AFFiNE                                                 | [📖](07_data-services.md)              |
| **Media & Entertainment**        | 9     | Jellyfin, *arr stack, Kavita                                             | [📖](08_media-entertainment.md)        |
| **Productivity & Collaboration** | 12    | OpenCloud, N8N, Syncthing, Vert.sh, Excalidraw, ChartDB, DrawDB             | [📖](09_productivity-collaboration.md) |
| **Monitoring & Management**      | 6     | Uptime Kuma, Beszel, Infisical, Arcane, Glance, Sablier                  | [📖](10_monitoring-management.md)      |

## Complete Service Reference

| Service                                                           | Docs                                            | Port             | Network                                             | Domain                    | Purpose                                   |
| ----------------------------------------------------------------- | ----------------------------------------------- | ---------------- | --------------------------------------------------- | ------------------------- | ----------------------------------------- |
| [**adguard**](../../services/adguard/compose.yml)             | [📖](../../services/adguard/documentation.md)       | 53,3333,8989     | proxy                                               | adguard.alimunee.com      | DNS filtering & ad blocking               |
| [**affine**](../../services/affine/compose.yml)               | [📖](../../services/affine/documentation.md)        | 3010             | proxy                                               | notes.alimunee.com        | Knowledge base (Notion alternative)       |
| [**bazarr**](../../services/bazarr/compose.yml)               | [📖](../../services/bazarr/documentation.md)        | 6767             | proxy                                               | bazarr.alimunee.com       | Subtitle management for media             |
| [**beszel**](../../services/beszel/compose.yml)               | [📖](../../services/beszel/documentation.md)        | 8090             | proxy                                               | monitor.alimunee.com      | Lightweight system & Docker monitoring    |
| [**checkmate**](../../services/checkmate/compose.yml)         | [📖](../../services/checkmate/documentation.md)     | 52345            | proxy, checkmate_internal                           | checkmate.alimunee.com    | Uptime & infrastructure monitoring        |
| [**cloudflared**](../../services/cloudflared/compose.yml)     | [📖](../../services/cloudflared/documentation.md)   | -                | proxy                                               | -                         | Cloudflare Tunnel service                 |
| [**Vert.sh**](../../services/vert/compose.yml)                | [📖](../../services/vert/documentation.md)          | 80               | proxy                                               | convert.alimunee.com      | WebAssembly file converter (250+ formats) |
| [**excalidraw**](../../services/excalidraw/compose.yml)       | [📖](../../services/excalidraw/documentation.md)    | 80               | proxy                                               | draw.alimunee.com         | Virtual whiteboard & diagramming tool     |
| [**chartdb**](../../services/chartdb/compose.yml)             | [📖](../../services/chartdb/documentation.md)       | 80               | proxy                                               | chartdb.alimunee.com      | Database schema design & visualization    |
| [**drawdb**](../../services/drawdb/compose.yml)               | [📖](../../services/drawdb/documentation.md)        | 80               | proxy                                               | drawdb.alimunee.com       | Database diagram editor & SQL generator   |
| [**arcane**](../../services/arcane/compose.yml)               | [📖](../../services/arcane/documentation.md)        | 3552             | proxy                                               | manage.alimunee.com       | Modern Docker management UI               |
| [**flaresolverr**](../../services/flaresolverr/compose.yml)   | [📖](../../services/flaresolverr/documentation.md)  | 8191             | proxy                                               | flaresolverr.alimunee.com | Cloudflare bypass service                 |
| [**flood**](../../services/flood/compose.yml)                 | [📖](../../services/flood/documentation.md)         | 3000             | proxy                                               | flood.alimunee.com        | Modern qBittorrent web UI                 |
| [**glance**](../../services/glance/compose.yml)               | [📖](../../services/glance/documentation.md)        | 8080             | proxy                                               | glance.alimunee.com       | System dashboard & monitoring             |
| [**immich**](../../services/immich/compose.yml)               | [📖](../../services/immich/documentation.md)        | 2283             | proxy, immich_internal                              | photos.alimunee.com       | Photo management & AI features (GPU ML)   |
| [**infisical**](../../services/infisical/compose.yml)         | [📖](../../services/infisical/documentation.md)     | 8080             | proxy, infisical_internal                           | secrets.alimunee.com      | Secrets & environment management          |
| [**it-tools**](../../services/it-tools/compose.yml)           | [📖](../../services/it-tools/documentation.md)      | 80               | proxy                                               | tools.alimunee.com        | Developer utilities & online tools        |
| [**jellyfin**](../../services/jellyfin/compose.yml)           | [📖](../../services/jellyfin/documentation.md)      | 8096             | proxy                                               | tv.alimunee.com           | Media streaming server (GPU transcoding)  |
| [**sablier**](../../services/sablier/compose.yml)             | [📖](../../services/sablier/documentation.md)       | 10000            | proxy                                               | -                         | Wake-on-demand scaling for 13 services    |
| [**seerr**](../../services/seerr/compose.yml)                 | [📖](../../services/seerr/documentation.md)         | 5055             | proxy                                               | request.alimunee.com      | Media request management                  |
| [**karakeep**](../../services/karakeep/compose.yml)           | [📖](../../services/karakeep/documentation.md)      | 3000             | proxy, karakeep_internal, db_network                | keep.alimunee.com         | AI-powered bookmark manager               |
| [**kavita**](../../services/kavita/compose.yml)               | [📖](../../services/kavita/documentation.md)        | 5000             | proxy                                               | comics.alimunee.com       | Digital library for comics & manga        |
| [**kuma**](../../services/kuma/compose.yml)                   | [📖](../../services/kuma/documentation.md)          | 3001             | proxy                                               | uptime.alimunee.com       | Uptime monitoring & status page           |
| [**linkwarden**](../../services/linkwarden/compose.yml)       | [📖](../../services/linkwarden/documentation.md)    | 3000             | proxy, linkwarden_internal                          | bookmarks.alimunee.com    | Bookmark & link manager                   |
| [**lobe-chat**](../../services/lobe-chat/compose.yml)         | [📖](../../services/lobe-chat/documentation.md)     | 3210             | proxy, lobe_chat_internal, db_network               | chat.alimunee.com         | AI chat interface with multi-LLM support  |
| [**n8n**](../../services/n8n/compose.yml)                     | [📖](../../services/n8n/documentation.md)           | 5678             | proxy, n8n_internal                                 | automate.alimunee.com     | Workflow automation platform              |
| [**opencloud**](../../services/opencloud/compose.yml)         | [📖](../../services/opencloud/documentation.md)     | 9200             | proxy, opencloud_internal                           | drive.alimunee.com        | Primary cloud storage with OnlyOffice     |
| [opencloud-onlyoffice](../../services/opencloud/compose.yml)  | [📖](../../services/opencloud/documentation.md)     | 80               | proxy, opencloud_internal                           | onlyoffice.alimunee.com   | Dedicated OnlyOffice for OpenCloud        |
| [**ntfy**](../../services/ntfy/compose.yml)                   | [📖](../../services/ntfy/documentation.md)          | 8888             | proxy                                               | notification.alimunee.com | Push notification service                 |
| [**outline**](../../services/outline/compose.yml)             | [📖](../../services/outline/documentation.md)       | 3000             | proxy, outline_internal, db_network                 | note.alimunee.com         | Wiki & knowledge base                     |
| [**paperless-gpt**](../../services/paperless-gpt/compose.yml) | [📖](../../services/paperless-gpt/documentation.md) | 8080             | proxy, paperless_internal                           | aidocs.alimunee.com       | AI enhancement for paperless-ngx          |
| [**paperless-ngx**](../../services/paperless-ngx/compose.yml) | [📖](../../services/paperless-ngx/documentation.md) | 8000             | proxy, paperless_internal, db_network               | docs.alimunee.com         | Document management with OCR              |
| [**postfix**](../../services/postfix/compose.yml)             | [📖](../../services/postfix/documentation.md)       | 25,587           | proxy                                               | -                         | SMTP relay server (Brevo upstream)        |
| [**prowlarr**](../../services/prowlarr/compose.yml)           | [📖](../../services/prowlarr/documentation.md)      | 9696             | proxy                                               | prowlarr.alimunee.com     | Indexer manager for *arr stack            |
| [**qbit**](../../services/qbit/compose.yml)                   | [📖](../../services/qbit/documentation.md)          | 8088,6881        | proxy                                               | qbit.alimunee.com         | BitTorrent download client                |
| [**radarr**](../../services/radarr/compose.yml)               | [📖](../../services/radarr/documentation.md)        | 7878             | proxy                                               | radarr.alimunee.com       | Movie collection manager                  |
| [**sonarr**](../../services/sonarr/compose.yml)               | [📖](../../services/sonarr/documentation.md)        | 8989             | proxy                                               | sonarr.alimunee.com       | TV show collection manager                |
| [**stirling-pdf**](../../services/stirling-pdf/compose.yml)   | [📖](../../services/stirling-pdf/documentation.md)  | 8080             | proxy                                               | pdf.alimunee.com          | PDF manipulation & processing tools       |
| [**pdfcraft**](../../services/pdfcraft/compose.yml)           | [📖](../../services/pdfcraft/documentation.md)      | 80               | proxy                                               | pdfcraft.alimunee.com     | Client-side PDF toolkit (90+ tools)       |
| [**syncthing**](../../services/syncthing/compose.yml)         | [📖](../../services/syncthing/documentation.md)     | 8384,22000,21027 | proxy                                               | sync.alimunee.com         | Decentralized file synchronization        |
| [**traefik**](../../services/traefik/compose.yml)             | [📖](../../services/traefik/documentation.md)       | 80,443,8080      | proxy                                               | - (port 8080 dashboard)   | Reverse proxy & load balancer             |
| [**vaultwarden**](../../services/vaultwarden/compose.yml)     | [📖](../../services/vaultwarden/documentation.md)   | 80,3012          | proxy                                               | vaultwarden.alimunee.com  | Password manager (Bitwarden-compatible)   |
| [**zitadel**](../../services/zitadel/compose.yml)             | [📖](../../services/zitadel/documentation.md)       | 8081,3001        | proxy, zitadel_internal                             | zitadel.alimunee.com      | Modern SSO & identity management          |

## Architecture Overview

Modern containerized infrastructure with:
- **Security**: Zitadel SSO + Cloudflare Tunnel
- **Routing**: Traefik reverse proxy with SSL
- **Monitoring**: Uptime Kuma + ntfy notifications
- **Storage**: Btrfs with compression and snapshots
- **DNS**: Standardized DNS (8.8.8.8, 1.1.1.1) across all services
- **Wake-on-demand**: Sablier scales 13 low-traffic services to zero; Traefik wakes them on first request

### Network Topology
```
Internet → Cloudflare → Cloudflared → Traefik → Services
                                                    ↓
                                    Zitadel (SSO)  |  Postfix (SMTP) → Brevo
                                                    ↓
                                DNS (8.8.8.8, 1.1.1.1) → All Containers
```

## Quick Commands

```bash
# Service health check
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"

# Test key services
curl -f https://traefik.alimunee.com/      # Traefik dashboard
curl -f https://uptime.alimunee.com/       # Monitoring
curl -f https://tv.alimunee.com/           # Jellyfin
```

## Navigation Guide

- **Service-specific details**: Check `/services/[service-name]/documentation.md`
- **Technical architecture**: Use category-specific documentation files
- **Troubleshooting**: See [11_troubleshooting.md](11_troubleshooting.md)
- **Operations**: See [12_operations.md](12_operations.md)

## Quick Reference Links

| Resource                  | Link                                                      | Purpose                 |
| ------------------------- | --------------------------------------------------------- | ----------------------- |
| **System Configuration**  | [`/HOMELAB/configs/`](../../configs/)                     | All system config files |
| **Service Documentation** | [`/HOMELAB/services/*/documentation.md`](../../services/) | Individual service docs |
| **Main Documentation**    | [`/HOMELAB/README.md`](../../README.md)                   | System overview         |

---

*For updates or questions, refer to the main [README.md](../../README.md).*
