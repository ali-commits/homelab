# Bazarr

**Purpose**: Automated subtitle downloader

| Configuration Setting | Value                       |
| --------------------- | --------------------------- |
| Image                 | `linuxserver/bazarr:latest` |
| Data Location         | `/storage/data/bazarr`      |
| Media Path - Movies   | `/storage/media/movies`     |
| Media Path - TV       | `/storage/media/tv`         |
| Media Path - Anime    | `/storage/media/anime`      |
| Port                  | `6767`                      |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | bazarr.alimunee.com                   |
| Cookie Domain     | Not explicitly configured             |
| TLS               | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin   | Not configured via environment variables |
