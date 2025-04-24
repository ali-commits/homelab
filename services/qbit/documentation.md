# qBittorrent

**Purpose**: BitTorrent client for downloading media

| Configuration Setting | Value                            |
| --------------------- | -------------------------------- |
| Image                 | `linuxserver/qbittorrent:latest` |
| PUID/PGID             | `1000`                           |
| Timezone              | `Asia/Kuala_Lumpur`              |
| WebUI Port            | `8088`                           |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | qbit.alimunee.com                     |
| Cookie Domain     | Not explicitly configured             |
| TLS               | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin   | Not applicable                                |

**Volume Mappings**:

| Volume        | Path                                  |
| ------------- | ------------------------------------- |
| Configuration | `/storage/data/qbittorrent:/config`   |
| Downloads     | `/storage/media/downloads:/downloads` |

**Network Settings**:

| Setting            | Value               |
| ------------------ | ------------------- |
| Web Interface Port | `8088`              |
| BitTorrent Port    | `6881 (TCP/UDP)`    |
| Domain             | `qbit.alimunee.com` |
| Network            | `proxy`             |
