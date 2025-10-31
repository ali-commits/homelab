# Nextcloud

**Purpose**: Self-hosted cloud storage and collaboration platform

**System Architecture**:

- Docker containers orchestrated with Docker Compose
- Components: Nextcloud application, PostgreSQL database, Redis cache, Nextcloud Cron
- Authentication: Integrated with Zitadel SSO via OpenID Connect

**Integration with Zitadel**:

Nextcloud is integrated with Zitadel for Single Sign-On (SSO) authentication, providing centralized user management.

### Zitadel Provider Configuration

1. **OAuth2/OpenID Provider**:

   - Name: Nextcloud OAuth
   - Client Type: Confidential
   - Client ID: [Client ID configured in Zitadel]
   - Redirect URIs: https://cloud.alimunee.com/apps/user_oidc/auth
   - Scopes: openid, email, profile

2. **Application Configuration**:
   - Name: Nextcloud
   - Provider: Nextcloud OAuth
   - Launch URL: https://cloud.alimunee.com

### Nextcloud OIDC Configuration

In Nextcloud, the OpenID Connect User Backend app is configured with the following settings:

- Enable OpenID Connect: Yes
- Use custom OpenID provider: Yes
- Discovery endpoint: https://auth.alimunee.com/application/o/nextcloud/.well-known/openid-configuration/
- Client ID: [Client ID from Zitadel]
- Client secret: [Client Secret from Zitadel]
- Automatically create users: Yes
- Automatically create groups: Yes
- REST API endpoint: https://auth.alimunee.com/api/v3/
- REST API token: [Zitadel API Token]
- Group mapping:
  - Zitadel Group: `Nextcloud Users`
  - Nextcloud Group: `users`

### Group-Based Access Control

Access to Nextcloud is restricted to members of the "Nextcloud Users" group in Zitadel. This is configured by:

1. Creating a "Nextcloud Users" group in Zitadel
2. Adding authorized users to this group
3. Binding the group directly to the Nextcloud application

- Storage: Btrfs filesystem at `/storage/nextcloud`
- Access: Traefik reverse proxy with Cloudflare for secure remote access

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | cloud.alimunee.com                          |
| Cookie Domain   | Not explicitly configured                   |
| TLS             | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin | Configured via environment variables        |

**Data Persistence**:

- `/storage/nextcloud/data`: User files and app data
- `/storage/nextcloud/db`: PostgreSQL database
- `/storage/nextcloud/redis`: Redis cache
- `/storage/nextcloud/config`: Configuration files

**Network Configuration**:

- Connected to `proxy` network for external access
- Additional `nextcloud_internal` network for container communication
- Traefik for routing and SSL termination

**Installed Applications**:

- Productivity: Calendar, Contacts, Tasks, Notes, Deck
- File Management: Text editor, PDF Viewer, Draw.io
- Integration: OpenID Connect user backend (Zitadel SSO)

**Performance Optimizations**:

- PHP parameters optimized (memory_limit, upload_max_filesize, opcache settings)
- Redis for memcache and locking
- PostgreSQL tuning
- Database maintenance via command-line tools

**Backup Procedures**:

- Automated Btrfs snapshots using Snapper
- PostgreSQL database dumps
- Configuration files backup

**Maintenance Commands**:

```bash
# Database optimization
docker exec -u www-data nextcloud php occ db:add-missing-indices
docker exec -u www-data nextcloud php occ maintenance:repair

# Storage cleanup
docker exec -u www-data nextcloud php occ trashbin:cleanup --all-users
docker exec -u www-data nextcloud php occ versions:cleanup

# System updates
docker exec -u www-data nextcloud php occ maintenance:mode --on
docker-compose pull
docker-compose up -d
docker exec -u www-data nextcloud php occ upgrade
docker exec -u www-data nextcloud php occ maintenance:mode --off
```

**Monitoring**:

- Integrated with Uptime Kuma for availability monitoring
- Notifications via NTFY
- Log monitoring for error detection
