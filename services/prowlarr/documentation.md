# Prowlarr

**Purpose**: Indexer manager/proxy for \*arr stack

| Configuration Setting | Value                         |
| --------------------- | ----------------------------- |
| Image                 | `linuxserver/prowlarr:latest` |
| Data Location         | `/storage/data/prowlarr `     |
| Port                  | `9696`                        |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | prowlarr.alimunee.com                 |
| Cookie Domain     | Not explicitly configured             |
| TLS               | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin   | Not applicable                                |

**Connected Services**:

| Service      | Connection          |
| ------------ | ------------------- |
| Radarr       | `radarr:7878`       |
| Sonarr       | `sonarr:8989`       |
| FlareSolverr | `flaresolverr:8191` |
| NTFY         | `http://ntfy`       |
| qBittorrent  | `qbittorrent:8080`  |
