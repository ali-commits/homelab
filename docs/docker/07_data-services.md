# Database-Backed Services

## Overview

Services requiring persistent data storage with databases.

## Database Infrastructure

### Database Types
- **PostgreSQL 16**: Primary database for most services
- **Redis**: Caching and session storage

### Database Storage Locations

| Service           | Database              | Storage Location                   |
| ----------------- | --------------------- | ---------------------------------- |
| **Immich**        | PostgreSQL (pgvector) | `/storage/data/immich/database`    |
| **Nextcloud**     | PostgreSQL            | `/storage/data/nextcloud/db`       |
| **Paperless-ngx** | PostgreSQL            | `/storage/data/paperless-ngx/db`   |
| **Zitadel**       | PostgreSQL            | `/storage/data/zitadel/zitadel-db` |
| **Karakeep**      | PostgreSQL            | `/storage/data/karakeep/db`        |
| **Infisical**     | PostgreSQL            | `/storage/data/infisical/db`       |
| **OnlyOffice**    | PostgreSQL            | `/storage/data/onlyoffice/db`      |
| **N8N**           | PostgreSQL            | `/storage/data/n8n/db`             |
| **AFFiNE**        | PostgreSQL (pgvector) | `/storage/data/affine/postgres`    |
| **Linkwarden**    | PostgreSQL            | `/storage/data/linkwarden/db`      |
| **Lobe Chat**     | PostgreSQL (pgvector) | `/storage/data/lobe-chat/db`       |
| **Outline**       | PostgreSQL            | `/storage/data/outline/db`         |

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

#### Productivity
- **Infisical** - Secrets management ([📖](../../services/infisical/documentation.md))
- **OnlyOffice** - Document editing ([📖](../../services/onlyoffice/documentation.md))
- **N8N** - Workflow automation ([📖](../../services/n8n/documentation.md))

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
- **immich_internal**, **nextcloud_internal**, **onlyoffice_internal**, etc.

## Backup Strategies

### PostgreSQL Backups
```bash
# Individual service backup
docker exec [service]-db pg_dump -U [user] [database] > backup-$(date +%Y%m%d).sql
```

### Other Backups
- **Redis** snapshots and configuration backups.

---

*For detailed database configuration and troubleshooting, refer to individual service documentation and [troubleshooting.md](troubleshooting.md)*
