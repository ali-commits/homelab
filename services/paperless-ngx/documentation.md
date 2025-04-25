# Paperless-ngx

**Purpose**: Self-hosted document management system for scanning, indexing, and archiving physical documents

| Configuration Setting | Value                           |
| --------------------- | ------------------------------- |
| Image                 | `paperlessngx/paperless-ngx:latest` |
| Database              | `PostgreSQL 15`                 |
| Cache                 | `Redis 7`                       |
| Memory Limits         | `2GB max, 512MB minimum`        |
| Timezone              | `Asia/Kuala_Lumpur`             |
| PUID/PGID             | `1000`                          |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | docs.alimunee.com                     |
| OCR Language      | English                               |
| TLS               | Disabled internally (handled by Cloudflare) |
| Duplicate Handling| Automatic deletion enabled            |

**Volume Mappings**:

| Volume          | Path                                      |
| --------------- | ----------------------------------------- |
| Data            | `/storage/data/paperless/data`            |
| Media           | `/storage/data/paperless/media`           |
| Export          | `/storage/data/paperless/export`          |
| Consume         | `/storage/data/paperless/consume`         |
| Database        | `/storage/data/paperless/db`              |

**Network Settings**:

| Setting            | Value                 |
| ------------------ | --------------------- |
| Web Interface Port | `8000`                |
| Domain             | `docs.alimunee.com`   |
| Networks           | `proxy` (external), `paperless_internal` (internal) |

**Security Considerations**:

- Database is isolated in an internal network
- Redis cache is isolated in an internal network
- Uses non-root user with PUID/PGID 1000
- Secrets should be changed before deployment:
  - PAPERLESS_SECRET_KEY
  - PAPERLESS_DBPASS

**Usage Instructions**:

1. Upload documents to the consume directory
2. Paperless will automatically process and OCR the documents
3. Access the web interface at docs.alimunee.com to manage documents
4. Documents can be tagged, categorized, and searched

**Maintenance**:

- Regularly backup the database and media folders
- Check consume directory for any failed documents
- Periodically check logs for OCR issues
