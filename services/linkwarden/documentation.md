# Linkwarden

## Purpose
Linkwarden is a self-hosted bookmark and archive manager that allows you to collect, organize, and preserve web content. It features automatic archiving, tagging, collaboration, and a modern web interface for managing your bookmarks and web archives.

## Configuration

| Variable              | Description                               | Default | Required |
| --------------------- | ----------------------------------------- | ------- |
| DB_PASSWORD           | PostgreSQL database password              | -       | Yes      |
| NEXTAUTH_SECRET       | NextAuth.js secret for session encryption | -       | Yes      |
| ZITADEL_CLIENT_ID     | Zitadel OIDC client ID                    | -       | Yes      |
| ZITADEL_CLIENT_SECRET | Zitadel OIDC client secret                | -       | Yes      |

### Ports
- **3000**: Web interface (HTTPS via Traefik)

### Domains
- **External**: https://bookmarks.alimunee.com
- **Internal**: http://linkwarden:3000

## Dependencies
- **Database**: PostgreSQL 16 (linkwarden-db)
- **SSO**: Zitadel OIDC provider
- **Networks**: proxy, linkwarden_internal, db_network
- **Storage**: /storage/data/linkwarden/ (app data and database)

## Setup

### 1. Configure Zitadel OIDC Application

1. **Access Zitadel Console**:
   - Navigate to https://zitadel.alimunee.com
   - Login as administrator

2. **Create New Application**:
   - Go to Projects → Default Project → Applications
   - Click "New Application"
   - Name: "Linkwarden"
   - Type: "Web Application"
   - Authentication Method: "PKCE"

3. **Configure Application Settings**:
   - **Redirect URIs**:
     - `https://bookmarks.alimunee.com/api/auth/callback/zitadel`
   - **Post Logout Redirect URIs**:
     - `https://bookmarks.alimunee.com`
   - **Scopes**: `openid`, `profile`, `email`

4. **Get Client Credentials**:
   - Copy the **Client ID** and **Client Secret**
   - Update `.env` file with these values

### 2. Generate Secure Secrets

```bash
# Generate NEXTAUTH_SECRET
openssl rand -base64 32

# Update .env file with secure values
```

### 3. Deploy the Service

```bash
cd services/linkwarden
docker compose up -d
```

### 4. Initial Setup

1. **Access the application**: https://bookmarks.alimunee.com
2. **Login with Zitadel**: Click "Sign in with Zitadel"
3. **Configure settings**: Set up collections, tags, and preferences

## Usage

### Web Interface
- **URL**: https://bookmarks.alimunee.com
- **Authentication**: Zitadel SSO (registration disabled)

### Core Features

#### **Bookmark Management**
- Save bookmarks with automatic metadata extraction
- Organize with collections and tags
- Full-text search across bookmarks and archives
- Bulk operations for managing multiple bookmarks

#### **Automatic Archiving**
- Create permanent archives of web pages
- PDF generation for long-term preservation
- Screenshot capture for visual reference
- Archive versioning and history

#### **Organization**
- **Collections**: Group related bookmarks
- **Tags**: Flexible categorization system
- **Favorites**: Quick access to important bookmarks
- **Search**: Advanced filtering and search capabilities

#### **Collaboration**
- Share collections with team members
- Collaborative bookmark management
- Permission-based access control
- Activity tracking and notifications

### API Access
- **REST API**: Available at https://bookmarks.alimunee.com/api/
- **Authentication**: Bearer token authentication
- **Documentation**: Built-in API documentation

## Integration

### SSO Configuration
- **Provider**: Zitadel OIDC
- **Authentication Flow**: Authorization Code with PKCE
- **User Mapping**: Email-based user identification
- **Registration**: Disabled (SSO users only)

### Browser Extensions
- Install Linkwarden browser extension for quick bookmarking
- Right-click context menu integration
- Automatic tag suggestions
- Bulk import from other bookmark managers

### Monitoring
- **Health Check**: Built-in API health endpoint
- **Uptime Kuma**: Monitor https://bookmarks.alimunee.com
- **ntfy Topic**: `homelab-alerts` for service issues

### Backup Integration
- **Database**: Included in PostgreSQL backup routines
- **Archives**: Btrfs snapshots of /storage/data/linkwarden/
- **Export**: Built-in export functionality for bookmarks

## Troubleshooting

### Common Issues

1. **SSO Login Problems**:
   ```bash
   # Check Zitadel connectivity
   curl -f https://zitadel.alimunee.com/.well-known/openid_configuration

   # Verify client configuration in Zitadel
   # Check redirect URIs match exactly
   ```

2. **Database Connection Issues**:
   ```bash
   # Check database connectivity
   docker exec linkwarden-db pg_isready -d linkwarden -U linkwarden

   # View database logs
   docker compose logs linkwarden-db
   ```

3. **Archive Generation Failures**:
   ```bash
   # Check application logs
   docker compose logs -f linkwarden

   # Verify disk space for archives
   df -h /storage/data/linkwarden/
   ```

4. **Performance Issues**:
   ```bash
   # Monitor resource usage
   docker stats linkwarden linkwarden-db

   # Check archive storage usage
   du -sh /storage/data/linkwarden/data/
   ```

### Debug Commands
```bash
# View application logs
docker compose logs -f linkwarden

# Check service status
docker compose ps

# Test database connection
docker exec linkwarden-db psql -U linkwarden -d linkwarden -c "SELECT version();"

# Verify SSO configuration
docker exec linkwarden env | grep -E "(ZITADEL|NEXTAUTH)"

# Check API health
curl -f https://bookmarks.alimunee.com/api/health
```

### SSO Troubleshooting
```bash
# Test OIDC discovery endpoint
curl -s https://zitadel.alimunee.com/.well-known/openid_configuration | jq

# Verify client configuration
# Check Zitadel logs for authentication attempts
# Ensure redirect URIs match exactly in Zitadel configuration
```

## Backup

### Database Backup
```bash
# Backup database
docker exec linkwarden-db pg_dump -U linkwarden linkwarden > linkwarden-db-$(date +%Y%m%d).sql

# Restore database
docker exec -i linkwarden-db psql -U linkwarden linkwarden < linkwarden-db-YYYYMMDD.sql
```

### Archive Backup
```bash
# Backup archives and data
sudo tar -czf linkwarden-data-$(date +%Y%m%d).tar.gz -C /storage/data linkwarden/

# Export bookmarks (via web interface)
# Go to Settings → Export → Download backup
```

### Full Backup
```bash
# Complete backup including configuration
sudo tar -czf linkwarden-full-$(date +%Y%m%d).tar.gz \
  -C /storage/data linkwarden/ \
  -C /HOMELAB/services linkwarden/
```

### Recovery Steps
1. Restore database from backup
2. Restore archive files and configuration
3. Restart all services
4. Verify SSO authentication
5. Test bookmark access and archive functionality

## Security Considerations

### Authentication Security
- **SSO Only**: Registration disabled, Zitadel authentication required
- **Session Management**: Secure session handling via NextAuth.js
- **HTTPS Only**: All communication encrypted via Traefik
- **CSRF Protection**: Built-in CSRF protection

### Data Privacy
- **Self-Hosted**: All bookmarks and archives stored locally
- **Archive Isolation**: Archives stored in isolated directory
- **Database Encryption**: PostgreSQL with encrypted connections
- **Network Isolation**: Internal networks for service communication

### Access Control
- **User-Based**: Each user sees only their bookmarks
- **Collection Sharing**: Granular sharing permissions
- **API Security**: Token-based API authentication
- **Audit Logging**: User activity tracking

## Use Cases

### Personal Knowledge Management
- Research bookmark collection and archiving
- Article and documentation preservation
- Reference material organization
- Long-term content preservation

### Team Collaboration
- Shared resource collections
- Research project collaboration
- Knowledge base development
- Content curation workflows

### Content Archiving
- Important webpage preservation
- Documentation backup
- Historical content snapshots
- Offline content access
