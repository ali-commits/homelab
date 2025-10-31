# Docker Infrastructure Overview

## Quick Status Dashboard
- **Total Services**: 46 deployed and running
- **Last Updated**: October 28, 2025
- **Infrastructure Health**: ✅ All systems operational

## Service Categories & Quick Access

| Category                         | Count | Key Services                                                             | Documentation                         |
| -------------------------------- | ----- | ------------------------------------------------------------------------ | ------------------------------------- |
| **Docker Networks**              | -     | Network topology & configuration                                         | [📖](01_docker-networks.md)            |
| **Storage & Volumes**            | -     | Filesystem, volumes, database storage                                    | [📖](02_storage-volumes.md)            |
| **Core Infrastructure**          | 4     | Traefik, Cloudflared, AdGuard, Watchtower                                | [📖](03_core-infrastructure.md)        |
| **Authentication**               | 1     | Zitadel                                                                  | [📖](04_authentication.md)             |
| **AI/ML Services**               | 4     | Lobe Chat, Karakeep, Paperless-GPT, Immich ML                            | [📖](05_ai-ml-services.md)             |
| **Notifications & SMTP**         | 2     | ntfy, Postfix                                                            | [📖](06_notifications-smtp.md)         |
| **Data Services**                | 15    | Nextcloud, Immich, Firefly III, Karakeep                                 | [📖](07_data-services.md)              |
| **Media & Entertainment**        | 10    | Jellyfin, *arr stack, Kavita, BookLore                                   | [📖](08_media-entertainment.md)        |
| **Productivity & Collaboration** | 12    | AFFiNE, OnlyOffice, N8N, Syncthing, Vert.sh, Excalidraw, ChartDB, DrawDB | [📖](09_productivity-collaboration.md) |
| **Monitoring & Management**      | 8     | Uptime Kuma, Beszel, Dockge, Komodo, Infisical, Dozzle, Checkmate        | [📖](10_monitoring-management.md)      |

## Complete Service Reference

| Service                                                           | Docs                                            | Port             | Network                                             | Domain                    | Purpose                                   |
| ----------------------------------------------------------------- | ----------------------------------------------- | ---------------- | --------------------------------------------------- | ------------------------- | ----------------------------------------- |
| [**adguard**](../services/adguard/docker-compose.yml)             | [📖](../services/adguard/documentation.md)       | 53,3333,8989     | proxy                                               | adguard.alimunee.com      | DNS filtering & ad blocking               |
| [**affine**](../services/affine/docker-compose.yml)               | [📖](../services/affine/documentation.md)        | 3010             | proxy                                               | notes.alimunee.com        | Knowledge base (Notion alternative)       |
| [**bazarr**](../services/bazarr/docker-compose.yml)               | [📖](../services/bazarr/documentation.md)        | 6767             | proxy                                               | bazarr.alimunee.com       | Subtitle management for media             |
| [**beszel**](../services/beszel/docker-compose.yml)               | [📖](../services/beszel/documentation.md)        | 8090             | proxy                                               | monitoring.alimunee.com   | Lightweight system & Docker monitoring    |
| [**booklore**](../services/booklore/docker-compose.yml)           | [📖](../services/booklore/documentation.md)      | 6060             | proxy, booklore_internal, mail_network              | books.alimunee.com        | Personal book collection manager          |
| [**checkmate**](../services/checkmate/docker-compose.yml)         | [📖](../services/checkmate/documentation.md)     | 52345            | proxy, checkmate_internal, db_network, mail_network | checkmate.alimunee.com    | Uptime & infrastructure monitoring        |
| [**cloudflared**](../services/cloudflared/docker-compose.yml)     | [📖](../services/cloudflared/documentation.md)   | -                | proxy                                               | -                         | Cloudflare Tunnel service                 |
| [**cloudreve**](../services/cloudreve/docker-compose.yml)         | [📖](../services/cloudreve/documentation.md)     | 5212             | proxy, cloudreve_internal                           | files.alimunee.com        | Cloud storage platform                    |
| [**Vert.sh**](../services/vert/docker-compose.yml)                | [📖](../services/vert/documentation.md)          | 80               | proxy                                               | convert.alimunee.com      | WebAssembly file converter (250+ formats) |
| [**dockge**](../services/dockge/docker-compose.yml)               | [📖](../services/dockge/documentation.md)        | 5001             | proxy                                               | dockge.alimunee.com       | Docker container management               |
| [**excalidraw**](../services/excalidraw/docker-compose.yml)       | [📖](../services/excalidraw/documentation.md)    | 80               | proxy                                               | draw.alimunee.com         | Virtual whiteboard & diagramming tool     |
| [**chartdb**](../services/chartdb/docker-compose.yml)             | [📖](../services/chartdb/documentation.md)       | 80               | proxy                                               | chartdb.alimunee.com      | Database schema design & visualization    |
| [**drawdb**](../services/drawdb/docker-compose.yml)               | [📖](../services/drawdb/documentation.md)        | 80               | proxy                                               | drawdb.alimunee.com       | Database diagram editor & SQL generator   |
| [**dozzle**](../services/dozzle/docker-compose.yml)               | [📖](../services/dozzle/documentation.md)        | 8080             | proxy                                               | logs.alimunee.com         | Real-time Docker log viewer               |
| [**firefly-iii**](../services/firefly-iii/docker-compose.yml)     | [📖](../services/firefly-iii/documentation.md)   | 8080             | proxy, firefly_internal                             | budget.alimunee.com       | Personal finance & budget management      |
| [**flaresolverr**](../services/flaresolverr/docker-compose.yml)   | [📖](../services/flaresolverr/documentation.md)  | 8191             | proxy                                               | flaresolverr.alimunee.com | Cloudflare bypass service                 |
| [**flood**](../services/flood/docker-compose.yml)                 | [📖](../services/flood/documentation.md)         | 3000             | proxy                                               | flood.alimunee.com        | Modern qBittorrent web UI                 |
| [**glance**](../services/glance/docker-compose.yml)               | [📖](../services/glance/documentation.md)        | 8080             | proxy                                               | glance.alimunee.com       | System dashboard & monitoring             |
| [**immich**](../services/immich/docker-compose.yml)               | [📖](../services/immich/documentation.md)        | 2283             | proxy, immich_internal                              | photos.alimunee.com       | Photo management & AI features (GPU ML)   |
| [**infisical**](../services/infisical/docker-compose.yml)         | [📖](../services/infisical/documentation.md)     | 8080             | proxy, infisical_internal, mail_network             | secrets.alimunee.com      | Secrets & environment management          |
| [**it-tools**](../services/it-tools/docker-compose.yml)           | [📖](../services/it-tools/documentation.md)      | 80               | proxy                                               | tools.alimunee.com        | Developer utilities & online tools        |
| [**jellyfin**](../services/jellyfin/docker-compose.yml)           | [📖](../services/jellyfin/documentation.md)      | 8096             | proxy                                               | tv.alimunee.com           | Media streaming server (GPU transcoding)  |
| [**jellyseerr**](../services/jellyseerr/docker-compose.yml)       | [📖](../services/jellyseerr/documentation.md)    | 5055             | proxy                                               | request.alimunee.com      | Media request management                  |
| [**karakeep**](../services/karakeep/docker-compose.yml)           | [📖](../services/karakeep/documentation.md)      | 3000             | proxy, karakeep_internal, db_network                | keep.alimunee.com         | AI-powered bookmark manager               |
| [**kavita**](../services/kavita/docker-compose.yml)               | [📖](../services/kavita/documentation.md)        | 5000             | proxy                                               | comics.alimunee.com       | Digital library for comics & manga        |
| [**komodo**](../services/komodo/docker-compose.yml)               | [📖](../services/komodo/documentation.md)        | 9120             | proxy, komodo_internal                              | komodo.alimunee.com       | Infrastructure management platform        |
| [**kuma**](../services/kuma/docker-compose.yml)                   | [📖](../services/kuma/documentation.md)          | 3001             | proxy                                               | uptime.alimunee.com       | Uptime monitoring & status page           |
| [**linkwarden**](../services/linkwarden/docker-compose.yml)       | [📖](../services/linkwarden/documentation.md)    | 3000             | proxy, linkwarden_internal                          | links.alimunee.com        | Bookmark & link manager                   |
| [**lobe-chat**](../services/lobe-chat/docker-compose.yml)         | [📖](../services/lobe-chat/documentation.md)     | 3210             | proxy, lobe_chat_internal, db_network               | chat.alimunee.com         | AI chat interface with multi-LLM support  |
| [**n8n**](../services/n8n/docker-compose.yml)                     | [📖](../services/n8n/documentation.md)           | 5678             | proxy, n8n_internal                                 | automate.alimunee.com     | Workflow automation platform              |
| [**nextcloud**](../services/nextcloud/docker-compose.yml)         | [📖](../services/nextcloud/documentation.md)     | 80               | proxy, nextcloud_internal                           | cloud.alimunee.com        | Personal cloud & file sharing             |
| [**ntfy**](../services/ntfy/docker-compose.yml)                   | [📖](../services/ntfy/documentation.md)          | 8888             | proxy                                               | notification.alimunee.com | Push notification service                 |
| [**onlyoffice**](../services/onlyoffice/docker-compose.yml)       | [📖](../services/onlyoffice/documentation.md)    | 80               | proxy, onlyoffice_internal                          | office.alimunee.com       | Document editing & collaboration          |
| [**paperless-gpt**](../services/paperless-gpt/docker-compose.yml) | [📖](../services/paperless-gpt/documentation.md) | 8080             | proxy, paperless_internal                           | aidocs.alimunee.com       | AI enhancement for paperless-ngx          |
| [**paperless-ngx**](../services/paperless-ngx/docker-compose.yml) | [📖](../services/paperless-ngx/documentation.md) | 8000             | proxy, paperless_internal, db_network, mail_network | docs.alimunee.com         | Document management with OCR              |
| [**postfix**](../services/postfix/docker-compose.yml)             | [📖](../services/postfix/documentation.md)       | 25               | mail_network                                        | -                         | SMTP relay server (Brevo upstream)        |
| [**prowlarr**](../services/prowlarr/docker-compose.yml)           | [📖](../services/prowlarr/documentation.md)      | 9696             | proxy                                               | prowlarr.alimunee.com     | Indexer manager for *arr stack            |
| [**qbit**](../services/qbit/docker-compose.yml)                   | [📖](../services/qbit/documentation.md)          | 8088,6881        | proxy                                               | qbit.alimunee.com         | BitTorrent download client                |
| [**radarr**](../services/radarr/docker-compose.yml)               | [📖](../services/radarr/documentation.md)        | 7878             | proxy                                               | radarr.alimunee.com       | Movie collection manager                  |
| [**sonarr**](../services/sonarr/docker-compose.yml)               | [📖](../services/sonarr/documentation.md)        | 8989             | proxy                                               | sonarr.alimunee.com       | TV show collection manager                |
| [**stirling-pdf**](../services/stirling-pdf/docker-compose.yml)   | [📖](../services/stirling-pdf/documentation.md)  | 8080             | proxy                                               | pdf.alimunee.com          | PDF manipulation & processing tools       |
| [**syncthing**](../services/syncthing/docker-compose.yml)         | [📖](../services/syncthing/documentation.md)     | 8384,22000,21027 | proxy                                               | sync.alimunee.com         | Decentralized file synchronization        |
| [**traefik**](../services/traefik/docker-compose.yml)             | [📖](../services/traefik/documentation.md)       | 80,443,8080      | proxy                                               | traefik.alimunee.com      | Reverse proxy & load balancer             |
| [**watchtower**](../services/watchtower/docker-compose.yml)       | [📖](../services/watchtower/documentation.md)    | -                | proxy                                               | -                         | Automated container updates               |
| [**zitadel**](../services/zitadel/docker-compose.yml)             | [📖](../services/zitadel/documentation.md)       | 8081,3001        | proxy, zitadel_internal                             | zitadel.alimunee.com      | Modern SSO & identity management          |

## Architecture Overview

Modern containerized infrastructure with:
- **Security**: Zitadel SSO + Cloudflare Tunnel
- **Routing**: Traefik reverse proxy with SSL
- **Monitoring**: Uptime Kuma + ntfy notifications
- **Storage**: Btrfs with compression and snapshots

### Network Topology
```
Internet → Cloudflare → Cloudflared → Traefik → Services
                                                    ↓
                                    Zitadel (SSO)  |  Postfix (SMTP) → Brevo
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
