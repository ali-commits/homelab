# Seerr

**Purpose**: Media request and discovery platform (unified replacement for Overseerr/Jellyseerr)

| Configuration Setting | Value                              |
| --------------------- | ---------------------------------- |
| Image                 | `ghcr.io/seerr-team/seerr:latest` |
| Data Location         | `/storage/data/jellyseerr`        |
| Port                  | `5055`                             |

**Configuration Details**:

| Configuration   | Details                                             |
|-----------------|-----------------------------------------------------|
| External Access | request.alimunee.com                                |
| Cookie Domain   | Not explicitly configured                           |
| TLS             | Disabled internally (handled by Cloudflare)         |
| User            | `node` (UID 1000, non-root — no PUID/PGID needed)  |

**Migration Notes**:

Migrated from `fallenbagel/jellyseerr:latest`. Data location kept at `/storage/data/jellyseerr` — seerr auto-migrates existing data on first startup. Before starting, permissions were fixed with:

```bash
docker run --rm -v /storage/data/jellyseerr:/data alpine chown -R 1000:1000 /data
```
