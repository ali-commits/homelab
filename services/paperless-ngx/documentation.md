# Paperless-ngx

## Purpose
Paperless-ngx is a community-supported document management system that transforms physical documents into a searchable online archive. It features OCR, automatic tagging, full-text search, and a modern web interface for organizing andeving documents.

## Configuration

| Variable       | Description                      | Default | Required |
| -------------- | -------------------------------- | ------- | -------- |
| DB_PASSWORD    | PostgreSQL database password     | -       | Yes      |
| SECRET_KEY     | Django secret key for encryption | -       | Yes      |
| ADMIN_USER     | Initial admin username           | admin   | Yes      |
| ADMIN_PASSWORD | Initial admin password           | -       | Yes      |
| ADMIN_EMAIL    | Admin email address              | -       | Yes      |

### Ports
- **8000**: Web interface (HTTPS via Traefik)

### Domains
- **External**: https://docs.alimunee.com
- **Internal**: http://paperless-ngx:8000

## Dependencies
- **Database**: PostgreSQL 16 (paperless-db)
- **Cache**: Redis (paperless-redis)
- **OCR**: Apache Tika (paperless-tika)
- **PDF Processing**: Gotenberg (paperless-gotenberg)
- **Networks**: proxy, paperless_internal, db_network, mail_network
- **Storage**: /storage/paperless-ngx/ (documents), /storage/data/paperless-ngx/ (app data)

## Setup

1. **Generate secure credentials**:
   ```bash
   # Generate SECRET_KEY
   openssl rand -base64 32

   # Update .env file with secure passwords
   ```

2. **Deploy the service**:
   ```bash
   cd services/paperless-ngx
   docker compose up -d
   ```

3. **Initial setup**:
   - Access https://docs.alimunee.com
   - Login with admin credentials from .env
   - Configure document types, tags, and correspondents
   - Set up consumption rules and workflows

4. **Configure document consumption**:
   - Place documents in `/storage/paperless-ngx/consume/`
   - Documents are automatically processed and imported
   - Use subdirectories for automatic tagging

## Usage

### Web Interface
- **URL**: https://docs.alimunee.com
- **Features**: Document search, tagging, OCR results, workflow management

### Document Processing
- **Consume Directory**: `/storage/paperless-ngx/consume/`
- **Export Directory**: `/storage/paperless-ngx/export/`
- **Supported Formats**: PDF, images (PNG, JPG, TIFF), Office documents

### OCR and Search
- **Languages**: Multi-language support configured (English, Arabic, Malay)
  - **OCR Languages**: `eng+ara+msa` (combined detection)
  - **Date Parsing**: `en+ar+ms` (supports dates in all three languages)
- **Full-text Search**: All document content is indexed and searchable in all configured languages
- **Automatic Tagging**: Based on document content and folder structure

### API Access
- **REST API**: Available at https://docs.alimunee.com/api/
- **Authentication**: Token-based authentication
- **Documentation**: Built-in API documentation

## Integration

### Email Processing
- **SMTP**: Configured to use Postfix relay
- **Notifications**: Document processing status, user notifications
- **Email Import**: Can be configured to process emails as documents

### SSO Integration
Configure OIDC/SAML in Paperless settings:
1. Admin > Settings > Authentication
2. Configure Zitadel integration
3. Map user attributes and groups

### Monitoring
- **Health Checks**: All services have health endpoints
- **Uptime Kuma**: Monitor https://docs.alimunee.com
- **ntfy Topic**: `homelab-alerts` for processing issues

### Backup Integration
- **Database**: Included in PostgreSQL backup routines
- **Documents**: Btrfs snapshots of /storage/paperless-ngx/
- **Export**: Regular exports to /storage/paperless-ngx/export/

## Troubleshooting

### Common Issues

1. **OCR Problems**:
   ```bash
   # Check Tika service
   docker compose logs paperless-tika

   # Test OCR processing
   docker exec paperless-ngx python manage.py document_retagger --tags --overwrite

   # Check available OCR languages
   docker exec paperless-ngx tesseract --list-langs

   # Test specific language OCR
   docker exec paperless-ngx python manage.py document_consumer --override-lang ara
   ```

2. **Database Connection Issues**:
   ```bash
   # Check database connectivity
   docker exec paperless-ngx python manage.py check --database default

   # View database logs
   docker compose logs paperless-db
   ```

3. **Document Processing Stuck**:
   ```bash
   # Check consumer logs
   docker compose logs -f paperless-ngx | grep consumer

   # Restart document processing
   docker exec paperless-ngx python manage.py document_consumer
   ```

4. **Permission Issues**:
   ```bash
   # Fix consume directory permissions
   sudo chown -R 1000:1000 /storage/paperless-ngx/consume/

   # Check container user
   docker exec paperless-ngx id
   ```

### Debug Commands
```bash
# View application logs
docker compose logs -f paperless-ngx

# Check service status
docker compose ps

# Access Django shell
docker exec -it paperless-ngx python manage.py shell

# Run management commands
docker exec paperless-ngx python manage.py --help

# Check document processing queue
docker exec paperless-ngx python manage.py document_index reindex
```

### Performance Tuning
```bash
# Monitor resource usage
docker stats paperless-ngx paperless-db paperless-redis

# Check processing performance
docker exec paperless-ngx python manage.py check_sanity

# Optimize database
docker exec paperless-db psql -U paperless -d paperless -c "VACUUM ANALYZE;"
```

## Backup

### Database Backup
```bash
# Backup database
docker exec paperless-db pg_dump -U paperless paperless > paperless-db-$(date +%Y%m%d).sql

# Restore database
docker exec -i paperless-db psql -U paperless paperless < paperless-db-YYYYMMDD.sql
```

### Document Export
```bash
# Export all documents
docker exec paperless-ngx python manage.py document_exporter /usr/src/paperless/export/

# Backup consume and export directories
sudo tar -czf paperless-docs-$(date +%Y%m%d).tar.gz -C /storage paperless-ngx/
```

### Full Backup
```bash
# Complete backup including configuration
sudo tar -czf paperless-full-$(date +%Y%m%d).tar.gz \
  -C /storage/data paperless-ngx/ \
  -C /storage paperless-ngx/
```

### Recovery Steps
1. Restore database from backup
2. Restore document files and configuration
3. Restart all services
4. Verify document accessibility and search functionality
5. Re-run OCR processing if needed:
   ```bash
   docker exec paperless-ngx python manage.py document_retagger --overwrite
   ```
