# Radarr

**Purpose**: Automated movie collection manager and downloader

| Configuration Setting | Value                       |
| --------------------- | --------------------------- |
| Image                 | `linuxserver/radarr:latest` |
| Data Location         | `/storage/data/radarr`      |
| Media Path            | `/storage/media/movies`     |
| Downloads Path        | `/storage/media/downloads`  |
| Port                  | `7878`                      |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | radarr.alimunee.com                   |
| Cookie Domain     | Not explicitly configured             |
| TLS               | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin   | Not applicable                                |
