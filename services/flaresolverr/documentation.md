# FlareSolverr

**Purpose**: Proxy service to bypass Cloudflare protection

| Configuration Setting | Value                                      |
| --------------------- | ------------------------------------------ |
| Image                 | `ghcr.io/flaresolverr/flaresolverr:latest` |
| Port                  | `8191`                                     |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | flaresolverr.alimunee.com             |
| Cookie Domain     | Not explicitly configured             |
| TLS               | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin   | Not applicable                                |
