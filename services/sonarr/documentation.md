# Sonarr

**Purpose**: Automated TV show and anime collection manager

| Configuration Setting | Value                       |
| --------------------- | --------------------------- |
| Image                 | `linuxserver/sonarr:latest` |
| Data Location         | `/storage/data/sonarr`      |
| Media Paths - TV      | `/tv`                       |
| Media Paths - Anime   | `/anime`                    |
| Downloads Path        | `/downloads`                |
| Port                  | `8989`                      |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | sonarr.alimunee.com                   |
| Cookie Domain     | Not explicitly configured             |
| TLS               | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin   | Not applicable                                |
