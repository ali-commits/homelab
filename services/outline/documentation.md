# Outline Service Documentation

## Overview

Outline is a modern, fast wiki and knowledge base for teams. It features real-time collaborative editing, rich markdown support, document versioning, and powerful search capabilities. This deployment provides a self-hosted Outline instance accessible at `https://note.alimunee.com`.

## Purpose

- **Knowledge Management**: Centralized documentation and wiki for personal/family use
- **Collaborative Editing**: Real-time collaborative document editing
- **Rich Content**: Support for markdown, code blocks, diagrams, and embeds
- **Organization**: Collections, nested documents, and powerful search
- **Version Control**: Complete document revision history

## Architecture

The service consists of three containers:

- **outline**: Main application server (Node.js)
- **outline-db**: PostgreSQL 16 database for data storage
- **outline-redis**: Redis cache for session management and real-time collaboration

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `DB_PASSWORD` | PostgreSQL database password | (generated) | Yes |
| `SECRET_KEY` | Application secret for encryption | (generated) | Yes |
| `UTILS_SECRET` | Additional secret for utilities | (generated) | Yes |

### Application Settings

| Setting | Value | Description |
|---------|-------|-------------|
| `URL` | `https://note.alimunee.com` | Public URL for the instance |
| `PORT` | `3000` | Internal application port |
| `FILE_STORAGE` | `local` | Storage backend (using local filesystem) |
| `FILE_STORAGE_LOCAL_ROOT_DIR` | `/var/lib/outline/data` | Directory for file uploads |
| `FILE_STORAGE_UPLOAD_MAX_SIZE` | `26214400` (25MB) | Maximum upload file size |
| `DEFAULT_LANGUAGE` | `en_US` | Default interface language |
| `ENABLE_UPDATES` | `true` | Enable automatic update notifications |

### SMTP Configuration

Email notifications are configured through the Postfix relay:

| Variable | Value | Description |
|----------|-------|-------------|
| `SMTP_HOST` | `postfix` | SMTP relay server |
| `SMTP_PORT` | `25` | SMTP port |
| `SMTP_FROM_EMAIL` | `outline@alimunee.com` | From address |
| `SMTP_REPLY_EMAIL` | `outline@alimunee.com` | Reply-to address |
| `SMTP_SECURE` | `false` | TLS (handled by Cloudflare) |

## Storage

### Data Volumes

| Path | Purpose | Storage Type |
|------|---------|--------------|
| `/storage/data/outline/data` | File uploads and attachments | HDD |
| `/storage/data/outline/db` | PostgreSQL database | HDD |
| `/storage/data/outline/redis` | Redis persistence | HDD |

## Dependencies

### Required Services

- **PostgreSQL 16**: Primary database
- **Redis 7**: Cache and session store
- **Postfix**: SMTP relay for email notifications

### Networks

- `proxy`: Traefik reverse proxy access
- `outline_internal`: Isolated network for Outline components
- `db_network`: Database connectivity
- `mail_network`: SMTP relay access

## Setup Instructions

### 1. Deploy the Service

```bash
cd /HOMELAB/services/outline
docker compose up -d
```

### 2. Monitor Deployment

```bash
# Watch container startup
docker compose logs -f

# Check container health
docker ps --filter name=outline
```

### 3. Initial Setup

1. Navigate to `https://note.alimunee.com`
2. Create the first admin account
3. Configure team name and branding
4. Create your first collection

### 4. Authentication Setup (Optional)

After initial setup, configure SSO with Zitadel:

1. In Zitadel, create a new application:
   - Application Type: Web
   - Authentication Method: PKCE
   - Redirect URIs: `https://note.alimunee.com/auth/oidc.callback`

2. Update the `.env` file with OIDC settings:

```bash
OIDC_CLIENT_ID=your_client_id
OIDC_CLIENT_SECRET=your_client_secret
OIDC_AUTH_URI=https://zitadel.alimunee.com/oauth/v2/authorize
OIDC_TOKEN_URI=https://zitadel.alimunee.com/oauth/v2/token
OIDC_USERINFO_URI=https://zitadel.alimunee.com/oidc/v1/userinfo
OIDC_USERNAME_CLAIM=preferred_username
OIDC_DISPLAY_NAME=Zitadel SSO
OIDC_SCOPES=openid profile email
```

3. Restart the service:

```bash
docker compose down && docker compose up -d
```

## Usage

### Access Points

- **Web Interface**: `https://note.alimunee.com`
- **API Endpoint**: `https://note.alimunee.com/api`
- **Health Check**: `https://note.alimunee.com/`

### Features

#### Document Management

- Create and organize documents in collections
- Real-time collaborative editing
- Markdown and rich text support
- Version history and document revisions
- Document templates

#### Search & Discovery

- Full-text search across all documents
- Search within collections
- Recently viewed and starred documents
- Document backlinks

#### Organization

- Collections for grouping related content
- Nested document structure
- Tags and labels
- Public/private document visibility

#### Collaboration

- Real-time collaborative editing
- Document comments and discussions
- User mentions and notifications
- Share links with customizable permissions

### API Access

Generate an API token from Settings → Tokens:

```bash
# Example: List all documents
curl -X POST https://note.alimunee.com/api/documents.list \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

## Maintenance

### Backups

The service data is automatically backed up via Kopia:

```bash
# Manual backup trigger
sudo systemctl start kopia-backup.service

# Verify backup status
sudo systemctl status kopia-backup.service
```

### Updates

Watchtower automatically updates the container:

```bash
# Manual update
docker compose pull
docker compose up -d
```

### Database Maintenance

```bash
# Database backup
docker exec outline-db pg_dump -U outline outline > outline_backup.sql

# Database restore
cat outline_backup.sql | docker exec -i outline-db psql -U outline outline

# Vacuum database
docker exec outline-db psql -U outline -d outline -c "VACUUM ANALYZE;"
```

### Logs

```bash
# View application logs
docker compose logs -f outline

# View database logs
docker compose logs -f outline-db

# View Redis logs
docker compose logs -f outline-redis
```

## Troubleshooting

### Service Won't Start

1. Check container logs:

```bash
docker compose logs outline
```

2. Verify database connectivity:

```bash
docker exec outline-db pg_isready -U outline -d outline
```

3. Check Redis:

```bash
docker exec outline-redis redis-cli ping
```

### Database Connection Issues

```bash
# Check database health
docker compose ps outline-db

# Restart database
docker compose restart outline-db

# Check database logs
docker compose logs outline-db
```

### File Upload Issues

1. Check storage permissions:

```bash
ls -la /storage/data/outline/data
```

2. Verify disk space:

```bash
df -h /storage
```

3. Check upload size limits in environment variables

### Email Notifications Not Working

1. Verify Postfix connectivity:

```bash
docker exec outline nc -zv postfix 25
```

2. Check SMTP configuration in environment variables

3. Review mail logs:

```bash
docker logs postfix
```

### 404 Errors

1. Verify Traefik labels:

```bash
docker inspect outline | grep traefik
```

2. Check Traefik dashboard for routing configuration

3. Ensure `URL` environment variable matches domain

## Performance Optimization

### Database Tuning

The PostgreSQL instance is configured with basic settings. For better performance with large datasets:

```bash
# Add to outline-db environment in docker-compose.yml
command: >
  postgres
  -c shared_buffers=256MB
  -c effective_cache_size=1GB
  -c maintenance_work_mem=64MB
  -c checkpoint_completion_target=0.9
```

### Redis Configuration

Redis is configured with persistence (RDB snapshots every 60 seconds). Adjust in `docker-compose.yml` if needed:

```yaml
command: redis-server --save 300 10 --maxmemory 512mb --maxmemory-policy allkeys-lru
```

### File Storage

Currently using local file storage. For S3 compatibility:

1. Update `.env`:

```bash
FILE_STORAGE=s3
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1
AWS_S3_UPLOAD_BUCKET_NAME=outline-uploads
AWS_S3_UPLOAD_BUCKET_URL=https://s3.amazonaws.com
```

## Security Considerations

### Access Control

- Configure proper user roles (Admin, Member, Viewer)
- Use SSO for centralized authentication
- Enable document-level permissions
- Review shared document links regularly

### Network Security

- Service accessible only through Traefik (HTTPS)
- Database and Redis isolated in internal networks
- No direct external access to backend services

### Data Protection

- All secrets stored in `.env` file
- Database encrypted at rest (Btrfs encryption)
- Regular automated backups via Kopia
- Document version history maintained

### Updates

- Watchtower enabled for automatic security updates
- Monitor Outline releases for critical patches
- Database backed up before major version updates

## Integration

### Monitoring

Service monitored via:

- **Uptime Kuma**: Availability monitoring
- **Watchtower**: Update notifications
- **ntfy**: Critical alerts

### Backup Integration

- Included in Kopia backup schedule
- Database snapshots via Snapper
- Configuration files version controlled

### SSO Integration

Compatible with Zitadel OIDC:

- Centralized user management
- Single sign-on across homelab services
- Role-based access control

## Resources

- **Official Documentation**: <https://docs.getoutline.com/>
- **GitHub Repository**: <https://github.com/outline/outline>
- **API Documentation**: <https://www.getoutline.com/developers>
- **Docker Image**: <https://hub.docker.com/r/outlinewiki/outline>

## Support & Community

- **GitHub Issues**: <https://github.com/outline/outline/issues>
- **Discord Community**: <https://discord.gg/outline>
- **Feature Requests**: <https://github.com/outline/outline/discussions>
