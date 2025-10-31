# Uptime Kuma

**Purpose**: Self-hosted monitoring tool and status page

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | uptime.alimunee.com                         |
| Cookie Domain   | Not explicitly configured                   |
| TLS             | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin | Not applicable                              |

**Network Configuration**:

- Web Interface: Port 3001
- Domain: uptime.alimunee.com
- Connected to proxy network

**Dependencies**:

- Traefik for routing
- Zitadel for authentication
