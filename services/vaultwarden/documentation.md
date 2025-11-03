# Vaultwarden

## Purpose
Vaultwarden is a lightweight, self-hosted alternative to Bitwarden that provides a Rust-based implementation of the Bitwarden server API. It is compatible with all Bitwarden clients (web, mobile, desktop, browser extensions) and offers a resource-efficient solution for personal and family password management with end-to-end encryption.

## Configuration

| Variable          | Description                                    | Default                 | Required |
| ----------------- | ---------------------------------------------- | ----------------------- | -------- |
| ADMIN_TOKEN       | Admin panel access token                       | -                       | Yes      |
| SIGNUPS_ALLOWED   | Allow new user registrations                   | true                    | No       |
| SIGNUPS_VERIFY    | Require email verification for signups         | true                    | No       |
| SMTP_HOST         | SMTP server hostname                           | postfix                 | Yes      |
| SMTP_FROM         | Email sender address                            | vaultwarden@alimunee.com| Yes      |
| SMTP_FROM_NAME    | Email sender display name                       | Vaultwarden             | No       |
| SMTP_PORT         | SMTP server port                                | 25                      | Yes      |
| SMTP_SECURITY     | SMTP security method (starttls, force_tls, none)| starttls                | Yes      |
| SMTP_USERNAME     | SMTP authentication username                   | -                       | No       |
| SMTP_PASSWORD     | SMTP authentication password                   | -                       | No       |

### Ports
- **80**: Web interface (HTTPS via Traefik)
- **3012**: WebSocket notifications (internal)

### Domains
- **External**: https://vaultwarden.alimunee.com
- **Internal**: http://vaultwarden:80

## Dependencies
- **SMTP Relay**: Postfix (mail_network)
- **Networks**: proxy, mail_network
- **Storage**: /storage/data/vaultwarden/ (SQLite database, attachments, icons)
- **Database**: SQLite (embedded, no external database required)

## Setup

### 1. Generate Admin Token

```bash
# Generate secure admin token
openssl rand -base64 32

# Update .env file with generated token
```

### 2. Configure SMTP (Optional but Recommended)

The service is pre-configured to use the Postfix SMTP relay. If you need custom SMTP settings:

1. Update `.env` file with your SMTP credentials
2. Set `SMTP_SECURITY` to match your provider (starttls, force_tls, or none)
3. If authentication is required, set `SMTP_USERNAME` and `SMTP_PASSWORD`

### 3. Deploy the Service

```bash
cd services/vaultwarden
docker compose up -d
```

### 4. Initial Setup

1. **Access the application**: https://vaultwarden.alimunee.com
2. **Create admin account**: 
   - Click "Create Account" (if `SIGNUPS_ALLOWED=true`)
   - Or use the admin panel to create users
3. **Access admin panel**: 
   - Navigate to https://vaultwarden.alimunee.com/admin
   - Use the `ADMIN_TOKEN` from your `.env` file
4. **Disable signups** (recommended after initial setup):
   ```bash
   # Update .env file
   SIGNUPS_ALLOWED=false
   
   # Restart service
   docker compose restart vaultwarden
   ```

### 5. Configure Clients

1. **Web Vault**: Access via https://vaultwarden.alimunee.com
2. **Browser Extensions**: 
   - Install Bitwarden extension
   - Set server URL to: https://vaultwarden.alimunee.com
3. **Mobile Apps**:
   - Install Bitwarden mobile app
   - Set server URL to: https://vaultwarden.alimunee.com
4. **Desktop Apps**:
   - Install Bitwarden desktop app
   - Set server URL to: https://vaultwarden.alimunee.com

## Usage

### Web Interface
- **URL**: https://vaultwarden.alimunee.com
- **Admin Panel**: https://vaultwarden.alimunee.com/admin
- **Authentication**: Email/password or SSO (if configured)

### Core Features

#### **Password Management**
- Secure password storage with end-to-end encryption
- Password generator with customizable options
- Password strength analysis
- Breach detection and alerts
- Secure sharing with family/team members

#### **Organization Management**
- **Organizations**: Group users for shared access
- **Collections**: Organize items within organizations
- **Groups**: User groups for easier permission management
- **Policies**: Enforce security policies (2FA, password requirements)

#### **Vault Items**
- **Logins**: Username/password combinations
- **Cards**: Credit/debit card information
- **Identities**: Personal information
- **Secure Notes**: Encrypted text storage
- **Files**: Secure file attachments (requires sufficient storage)

#### **Security Features**
- Two-Factor Authentication (TOTP, YubiKey, Duo)
- Master password encryption
- Secure sharing mechanisms
- Audit logs and event tracking
- Password history and versioning

### Admin Panel Features

Access the admin panel at `/admin` using your admin token:

- **User Management**: Create, edit, delete users
- **Organization Management**: Manage organizations and memberships
- **System Information**: View server stats and configuration
- **Logs**: View application logs
- **Settings**: Configure server-wide settings
- **Reports**: View usage statistics and events

### API Access
- **Bitwarden API**: Compatible with all Bitwarden clients
- **REST API**: https://vaultwarden.alimunee.com/api/
- **WebSocket**: Real-time sync notifications at `/notifications/hub`

## Integration

### SSO Configuration (Future)
Vaultwarden supports OpenID Connect (OIDC) for SSO authentication. Integration with Zitadel will be configured in a future update.

1. **Configure Zitadel Application**:
   - Create OIDC application in Zitadel
   - Set redirect URI: `https://vaultwarden.alimunee.com/sso-callback`

2. **Update Vaultwarden Configuration**:
   - Set `SSO_ENABLED=true`
   - Configure OIDC provider settings
   - Map user attributes

### SMTP Integration
- **Provider**: Postfix SMTP relay
- **From Address**: vaultwarden@alimunee.com
- **Purpose**: Email verification, invitations, alerts
- **Security**: STARTTLS encryption

### Monitoring
- **Health Check**: HTTP endpoint at root path
- **Uptime Kuma**: Monitor https://vaultwarden.alimunee.com
- **ntfy Topic**: `homelab-alerts` for service issues
- **Logs**: Application logs in container output

### Backup Integration
- **Database**: SQLite file at `/storage/data/vaultwarden/db.sqlite3`
- **Attachments**: `/storage/data/vaultwarden/attachments/`
- **Icons**: `/storage/data/vaultwarden/icon_cache/`
- **Backup Method**: Btrfs snapshots of `/storage/data/vaultwarden/`
- **Export**: Built-in export functionality via web interface

## Troubleshooting

### Common Issues

1. **WebSocket Connection Issues**:
   ```bash
   # Check Traefik WebSocket routing
   docker logs traefik | grep vaultwarden
   
   # Verify WebSocket endpoint is accessible
   curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
     https://vaultwarden.alimunee.com/notifications/hub
   ```

2. **Email Not Sending**:
   ```bash
   # Check Postfix connectivity
   docker exec vaultwarden nc -zv postfix 25
   
   # View SMTP logs
   docker compose logs vaultwarden | grep -i smtp
   
   # Test email configuration in admin panel
   # Navigate to Admin → Settings → SMTP Test
   ```

3. **Database Issues**:
   ```bash
   # Check SQLite database integrity
   docker exec vaultwarden sqlite3 /data/db.sqlite3 "PRAGMA integrity_check;"
   
   # View database size
   docker exec vaultwarden ls -lh /data/db.sqlite3
   
   # Backup database
   docker exec vaultwarden cp /data/db.sqlite3 /data/db.sqlite3.backup
   ```

4. **Client Connection Issues**:
   ```bash
   # Verify server URL is correct in client settings
   # Check if domain resolves correctly
   nslookup vaultwarden.alimunee.com
   
   # Test API endpoint
   curl -f https://vaultwarden.alimunee.com/api/health
   ```

5. **High Storage Usage**:
   ```bash
   # Check storage usage
   du -sh /storage/data/vaultwarden/*
   
   # Clean up old icons (admin panel → Settings → Tools → Clean Icons)
   # Or manually:
   find /storage/data/vaultwarden/icon_cache -type f -mtime +90 -delete
   ```

### Debug Commands
```bash
# View application logs
docker compose logs -f vaultwarden

# Check service status
docker compose ps

# Test health endpoint
curl -f http://localhost/ -H "Host: vaultwarden.alimunee.com"

# Verify environment variables
docker exec vaultwarden env | grep -E "(DOMAIN|SMTP|ADMIN)"

# Check WebSocket endpoint
docker exec vaultwarden netstat -tlnp | grep 3012

# View admin token (from .env)
grep ADMIN_TOKEN .env
```

### Performance Optimization

1. **Database Optimization**:
   ```bash
   # Run database vacuum (reduces file size)
   docker exec vaultwarden sqlite3 /data/db.sqlite3 "VACUUM;"
   
   # Analyze database for query optimization
   docker exec vaultwarden sqlite3 /data/db.sqlite3 "ANALYZE;"
   ```

2. **Storage Management**:
   - Regularly clean unused icons (admin panel)
   - Remove old attachments if needed
   - Monitor storage usage with Btrfs snapshots

3. **Memory Usage**:
   - Vaultwarden is memory-efficient by default
   - Monitor with: `docker stats vaultwarden`

## Backup

### Database Backup
```bash
# Backup SQLite database
docker exec vaultwarden sqlite3 /data/db.sqlite3 .dump > vaultwarden-db-$(date +%Y%m%d).sql

# Or copy database file directly
docker cp vaultwarden:/data/db.sqlite3 vaultwarden-db-$(date +%Y%m%d).sqlite3
```

### Full Backup
```bash
# Backup all data (database, attachments, icons)
sudo tar -czf vaultwarden-full-$(date +%Y%m%d).tar.gz \
  -C /storage/data vaultwarden/

# Backup including configuration
sudo tar -czf vaultwarden-complete-$(date +%Y%m%d).tar.gz \
  -C /storage/data vaultwarden/ \
  -C /HOMELAB/services vaultwarden/
```

### Automated Backup
```bash
# Add to backup script (example)
#!/bin/bash
BACKUP_DIR="/storage/backups/vaultwarden"
mkdir -p "$BACKUP_DIR"
docker exec vaultwarden sqlite3 /data/db.sqlite3 .dump | gzip > \
  "$BACKUP_DIR/vaultwarden-db-$(date +%Y%m%d).sql.gz"
```

### Recovery Steps
1. Stop Vaultwarden service
2. Restore database file to `/storage/data/vaultwarden/db.sqlite3`
3. Restore attachments and icons if applicable
4. Restart service
5. Verify data integrity
6. Test login and vault access

## Security Considerations

### Authentication Security
- **Master Password**: Strong encryption with PBKDF2-SHA256
- **Two-Factor Authentication**: TOTP, YubiKey, Duo support
- **Session Management**: Secure session handling
- **HTTPS Only**: All communication encrypted via Traefik
- **Admin Token**: Strong random token required for admin access

### Data Encryption
- **End-to-End Encryption**: All vault data encrypted client-side
- **Server-Side**: Encrypted at rest (database encryption)
- **Attachments**: Encrypted file storage
- **Transit**: HTTPS/TLS encryption

### Access Control
- **User-Based**: Each user has isolated vault
- **Organization Sharing**: Secure sharing with permission control
- **Admin Access**: Limited to admin token holders
- **Audit Logging**: User activity tracking

### Best Practices
1. **Disable Signups**: Set `SIGNUPS_ALLOWED=false` after initial setup
2. **Enable 2FA**: Encourage all users to enable two-factor authentication
3. **Regular Backups**: Automated database backups
4. **Strong Admin Token**: Use cryptographically secure random token
5. **Monitor Access**: Review admin panel logs regularly
6. **Update Regularly**: Keep Vaultwarden image updated via Watchtower

## Use Cases

### Personal Password Management
- Store personal passwords securely
- Generate strong passwords
- Access passwords across all devices
- Share passwords securely with family

### Family Password Sharing
- Create organization for family
- Share common passwords (WiFi, streaming services)
- Manage household accounts
- Secure document storage

### Team/Organization Use
- Shared team credentials
- Secure file attachments
- Organization policies enforcement
- Audit trails and access control

## Migration from Bitwarden

If migrating from official Bitwarden servers:

1. **Export from Bitwarden**:
   - Web vault → Settings → Tools → Export Vault
   - Choose format (JSON or CSV)

2. **Import to Vaultwarden**:
   - Access https://vaultwarden.alimunee.com
   - Settings → Tools → Import Data
   - Upload export file
   - Verify imported items

3. **Update Client Settings**:
   - Update server URL in all Bitwarden clients
   - Test sync functionality
   - Verify all data is accessible

