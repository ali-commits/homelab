# NTFY

**Purpose**: Self-hosted pub-sub notification service

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | ntfy.alimunee.com                     |
| Cookie Domain     | Not explicitly configured             |
| TLS               | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin   | Not applicable                                |

**Security**:

- Basic authentication enabled
- Access control for topics
- Behind reverse proxy configuration

**Network Configuration**:

- Web Interface: Port 8888:80
- Domain: ntfy.alimunee.com
