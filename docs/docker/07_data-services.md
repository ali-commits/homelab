# Database-Backed Services

## Overview

Services requiring persistent data storage with databases.

## Database Infrastructure

### Database Types
- **PostgreSQL 16**: Primary database for most services
- **MariaDB 11.4**: BookLore book collection management
- **Redis**: Caching and session storage

### Database Storage Locations

| Service | Database | Storage Location |
|---------|----------|------------------|
| **Immich** | PostgreSQL (pgvector) | `/storage/data/immich/database` |
| **Nextcloud** | PostgreSQL | `/storage/nextcloud/db` |
| **Paperless-ngx**stgreSQL | `/storage/data/paperless-ngx/db` |
| **Zitadel** | PostgreSQL |storage/data/zitadel/zitadel-db` |
| **Karakeep** | PostgreSQL | `/storage/data/karakeep/db` |
| **Firefly III** | PostgreSQL | `/storage/data/firefly-iii/db` |
| **Infisical** | PostgreSQL | `/storage/data/infisical/db` |
| **OnlyOffice** | PostgreSQL | `/storage/data/onlyoffice/db` |
| **N8N** | PostgreSQL | `/storage/n8n/db` |
| **AFFiNE** | PostgreSQL | `/storage/data/affine/db` |
| **Linkwarden** | PostgreSQL | `/storage/data/linkwarden/db` |
| **BookLore** | MariaDB | `/storage/data/booklore/db` |

## Services by Database Type

### PostgreSQL Services

#### Core Services
- **Immich** - Photo management & AI features ([📖](../../services/immich/documentation.md))
- **Nextcloud** - Personal cloud & file sharing ([📖](../../services/nextcloud/documentation.md))
- **Zitadel** - SSO & identity management ([📖](../../services/zitadel/documentation.md))

#### Document & Knowledge Management
- **Paperless-ngx** - Document management with OCR ([📖](../../services/paperless-ngx/documentation.md))
- **Karakeep** - AI-powered bookmark manager ([📖](../../services/karakeep/documentation.md))
- **AFFiNE** - Knowledge base ([📖](../../services/affine/documentation.md))
- **Linkwarden** - Bookmark & link manager ([📖](../../services/linkwarden/documentation.md))

#### Productivity & Finance
- III** - Personal finance management ([📖](../../services/firefly-iii/documentation.md))
- **Infisical** - Secrets management ([📖](../../services/infisical/documentation.md))
- **OnlyOffice** -ument editing ([📖](../../services/onlyoffice/documentation.md))
- **N8N** - Workflow automation ([📖](../../services/n8n/documentation.md))

### MariaDB Services
- **BookLore** - Book collection manager ([📖](../../services/booklore/documentation.md))

### Redis & Caching
- **Redis** used by multiple services for caching and task queues.

## Database Network Configuration

### db_network Usage
Services connecting to shared PostgreSQL instances use the `db_network`:

```yaml
networks:
  - proxy              # Web access via Traefik
  - db_network         # Shared database access
  - [service]_internal # Service-specific isolation
```

### Internal Networks
Each multi-container service uses its own internal network:
- **immich_internal**, **nextcloud_internal**, **firefly_internal**, etc.

## Backup Strategies

### PostgreSQL Backups
```bash
# Individual service backup
docker exec [service]-db pg_dump -U [user] [database] > backup-$(date +%Y%m%d).sql
```

### MariaDB Backups
```bash
# BookLore backup
docker exec booklore-db mariadb-dump -u booklore -p booklore > booklore-backup-$(date +%Y%m%d).sql
```

### Other Backups
- **Redis** snapshots and configuration backups.

---

*For detailed database configuration and troubleshooting, refer to individual service documentation and [troubleshooting.md](troubleshooting.md)*