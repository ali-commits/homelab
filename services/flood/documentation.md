# Flood

**Purpose**: Modern BitTorrent web client with a beautiful interface

| Configuration Setting | Value                |
| --------------------- | -------------------- |
| Image                 | `jesec/flood:latest` |
| PUID/PGID             | `1000`               |
| Timezone              | `Asia/Kuala_Lumpur`  |
| WebUI Port            | `3000`               |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | flood.alimunee.com                    |
| Cookie Domain     | Not explicitly configured             |
| TLS               | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin   | Not applicable                        |

**Volume Mappings**:

| Volume        | Path                              |
| ------------- | --------------------------------- |
| Configuration | `/storage/data/flood:/config`     |
| Downloads     | `/storage/media/downloads:/downloads` |
| Movies        | `/storage/media/movies:/movies`   |
| TV Shows      | `/storage/media/tv:/tv`           |
| Anime         | `/storage/media/anime:/anime`     |

**Network Settings**:

| Setting            | Value               |
| ------------------ | ------------------- |
| Web Interface Port | `3000`              |
| Domain             | `flood.alimunee.com` |
| Network            | `proxy`             |

**Setup Instructions**:
1. Start with: `docker compose up -d`
2. Access via: https://flood.alimunee.com
3. Configure download client connections (qBittorrent, etc.)
4. Set up media library paths as needed

**Notes**:
- Ensure the `proxy` network exists and Traefik is running
- DNS for `flood.alimunee.com` must point to your server's IP
- Flood acts as a web UI frontend for various download clients
- Can connect to qBittorrent, Transmission, rTorrent, and others
