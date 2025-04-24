# Linkwarden

**Purpose**: Self-hosted bookmark manager and link organizer with SSO integration

**System Architecture**:

- **Components**:

  - Linkwarden application server (Node.js/Next.js)
  - PostgreSQL database for data storage
  - Authentik for Single Sign-On (SSO)

**Configuration Details**:

| Configuration     | Details                                       |
|-------------------|-----------------------------------------------|
| External Access   | https://links.alimunee.com (via Cloudflare Tunnel) |
| Cookie Domain     | Not explicitly configured                     |
| TLS               | Handled by Cloudflare Tunnel                  |
| Bootstrap Admin   | Not explicitly configured                     |

**Note**: `docker-compose.yml` file not found for this service. Configuration details are based on existing documentation.

**Network Configuration**:

- Connected to two networks:
  - `proxy`: For external communication via Traefik
  - `internal`: For isolated database communication (named `linkwarden_internal`)
- Web Interface: Port 3000
- Traefik for routing and SSL termination

**OAuth Integration with Authentik**:

- Provider Type: OAuth2/OpenID Provider
- Client ID: CexvhAeQ6Tk7RIlzbq1oooMN9tu7VquRFkHsLIYw
- Redirect URIs:
  - `https://links.alimunee.com/api/auth/callback/authentik`
  - `https://links.alimunee.com/api/v1/auth/callback/authentik`
- Scopes: `openid`, `email`, `profile`

**Features**:

- Bookmark management and organization
- Link categorization and tagging
- User-friendly interface
- Authentication via Authentik SSO
- Resource-efficient (256MB-1GB RAM allocation)
- Link preview generation

**Maintenance Procedures**:

- Database backup:

  ```bash
  docker exec linkwarden-db pg_dump -U postgres postgres > linkwarden_backup_$(date +%Y%m%d).sql
  ```

- Data backup:

  ```bash
  tar -czvf linkwarden_data_$(date +%Y%m%d).tar.gz /storage/data/linkwarden
  ```

- Upgrade procedure:
  ```bash
  docker-compose pull linkwarden
  docker-compose up -d linkwarden
