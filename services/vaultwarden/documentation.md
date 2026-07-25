# Vaultwarden

**Status**: deployed and in use since 2026-07-25 · image pinned to `1.37.0` ·
signups closed after the initial account was created.

## Purpose
Vaultwarden is a lightweight, self-hosted alternative to Bitwarden that provides a Rust-based implementation of the Bitwarden server API. It is compatible with all Bitwarden clients (web, mobile, desktop, browser extensions) and offers a resource-efficient solution for personal and family password management with end-to-end encryption.

> **Scope: passwords, not machine secrets.** Vaultwarden implements Bitwarden's
> *Password Manager* API only. **Bitwarden Secrets Manager is not implemented**
> and upstream has declined to add it — it is a separately licensed product
> requiring proprietary web-vault code plus machine accounts and RBAC that
> Vaultwarden does not model. `bws`, access tokens, service accounts and the
> Secrets Manager SDKs will not work here. Use
> [Infisical](../infisical/documentation.md) (`secrets.alimunee.com`) for machine
> secrets. See [docs/docker/04_authentication.md](../../docs/docker/04_authentication.md)
> for the full split.

> **The image is pinned on purpose.** This service holds every credential, so an
> upgrade should be a decision rather than a side effect of a pull. 1.37.0 also
> carries nine security advisories and is the minimum version supporting
> Bitwarden clients 2026.7.0+ — running older risks confusing client-side
> connection and certificate errors. Re-pin deliberately when upgrading.

## Configuration

| Variable          | Description                                    | Value in use            | Required |
| ----------------- | ---------------------------------------------- | ----------------------- | -------- |
| ADMIN_TOKEN       | Admin panel token — **Argon2 PHC hash**        | `$argon2id$...`         | Yes      |
| SIGNUPS_ALLOWED   | Allow new user registrations                   | false (after setup)     | No       |
| SIGNUPS_VERIFY    | Require email verification for signups         | true                    | No       |
| IP_HEADER         | Header carrying the real client IP             | CF-Connecting-IP        | No       |
| IP_HEADER_TRUSTED_PROXIES | Which proxies may set that header       | local                   | No       |
| ENABLE_WEBSOCKET  | Live sync notifications (main port since 1.30) | true                    | No       |
| SMTP_HOST         | SMTP relay hostname                            | postfix_relay           | Yes      |
| SMTP_FROM         | Email sender address                           | vaultwarden@alimunee.com| Yes      |
| SMTP_FROM_NAME    | Email sender display name                      | Vaultwarden             | No       |
| SMTP_PORT         | SMTP relay port                                | 25                      | Yes      |
| SMTP_SECURITY     | SMTP security method                           | off                     | Yes      |
| SMTP_USERNAME     | SMTP auth username                             | *(empty)*               | No       |
| SMTP_PASSWORD     | SMTP auth password                             | *(empty)*               | No       |

> **SMTP must be port 25 with `SMTP_SECURITY=off`.** `postfix_relay` listens on
> **25 only** — its compose publishes `587:587` to the host, but nothing serves
> that port inside the container, so `SMTP_PORT=587` fails to connect and blocks
> registration whenever `SIGNUPS_VERIFY=true`. Postfix accepts unauthenticated
> mail from private ranges (`SMTP_NETWORKS`) and handles TLS itself on the
> upstream hop to Brevo.

> **`SMTP_USERNAME` / `SMTP_PASSWORD` must be absent, not empty.** Leaving them
> declared but blank makes Vaultwarden treat credentials as supplied and
> negotiate AUTH; Postfix advertises no AUTH mechanism, and registration fails
> with:
>
> ```
> SMTP client error: internal client error: No compatible authentication mechanism was found
> ```
>
> The message points at authentication mechanisms, which invites tinkering with
> `SMTP_SECURITY` or TLS — but the fix is to send no credentials at all. Delete
> both lines from `.env` rather than emptying them, and do not re-declare them in
> the compose `environment:` block. Confirm with:
>
> ```bash
> docker exec vaultwarden printenv SMTP_USERNAME   # must exit non-zero
> ```
>
> To check whether the relay offers AUTH at all, look for an `AUTH` line in the
> EHLO response — this deployment has none, which is expected and correct:
>
> ```bash
> docker exec vaultwarden curl -sS --url smtp://postfix_relay:25 \
>   --mail-from vaultwarden@alimunee.com --mail-rcpt postmaster@alimunee.com \
>   -T /dev/null -v 2>&1 | grep '^< 250'
> ```

> **`ADMIN_TOKEN` must be `$`-escaped in `.env`.** Compose interpolates the
> project `.env`, so an Argon2 PHC string is read as variable references and
> arrives blank. Write every `$` as `$$` in `.env`; the container receives the
> correct single-`$` value. Verify with
> `docker exec vaultwarden printenv ADMIN_TOKEN`. For the same reason
> `ADMIN_TOKEN` is **not** re-declared as `${ADMIN_TOKEN}` in the compose
> `environment:` block — it is supplied by `env_file` directly.

### Ports
- **80**: Web interface and WebSocket notifications (HTTPS terminated upstream)

> There is no port 3012. The standalone WebSocket listener was folded into the
> main port in Vaultwarden 1.30; a Traefik router pointing at 3012 targets a port
> nothing is listening on and breaks live sync.

### Domains
- **External**: https://vaultwarden.alimunee.com
- **Internal**: http://vaultwarden:80

## Dependencies
- **SMTP Relay**: Postfix (via proxy network)
- **Networks**: proxy
- **Storage**: /storage/data/vaultwarden/ (SQLite database, attachments, icons)
- **Database**: SQLite (embedded, no external database required)

## Setup

### 1. Generate the Admin Token

Vaultwarden wants an Argon2id PHC hash, not a plaintext secret — with plaintext
it logs a warning on every start. You still type the *original* secret at
`/admin`; only the stored form is hashed.

`vaultwarden hash` needs a TTY and fails when piped, so generate it with
`argon2` using Vaultwarden's "bitwarden" preset (m=65540, t=3, p=4):

```bash
SECRET='<the admin password you want to type at /admin>'
docker run --rm -i alpine:3.20 sh -c '
  apk add --no-cache argon2 openssl >/dev/null 2>&1
  read -r pw
  printf "%s" "$pw" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4
' <<<"$SECRET"
```

Put the result in `.env` with every `$` doubled (see the escaping note above),
then confirm the container received it intact:

```bash
docker exec vaultwarden printenv ADMIN_TOKEN   # expect a single-$ PHC string
docker logs vaultwarden | grep -i "plain text" # expect no output
```

### 2. Configure SMTP

Pre-configured against the `postfix_relay` container on the `proxy` network.
Use **port 25** with **`SMTP_SECURITY=off`** and empty credentials — see the
warning above for why 587/starttls silently fails here.

Verify the relay is actually reachable before relying on registration email:

```bash
docker exec vaultwarden curl -sS --url smtp://postfix_relay:25 \
  --mail-from vaultwarden@alimunee.com --mail-rcpt postmaster@alimunee.com \
  -T /dev/null -v 2>&1 | grep -E '^< (220|250)'
```

A `220 mail.alimunee.com ESMTP Postfix` banner means the path works.

For an end-to-end test that exercises Vaultwarden's own SMTP client — the thing
that actually fails during registration — use the admin test endpoint and then
read the relay log, which is where delivery is either confirmed or explained:

```bash
CJ=$(mktemp)
curl -sS -o /dev/null -c "$CJ" -X POST https://vaultwarden.alimunee.com/admin \
  -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "token=<admin token>"
curl -sS -b "$CJ" -X POST https://vaultwarden.alimunee.com/admin/test/smtp \
  -H 'Content-Type: application/json' -d '{"email":"you@example.com"}'
rm -f "$CJ"

docker logs postfix_relay --tail 20 | grep -E 'from=|to=|status='
```

`status=sent (250 ...)` confirms the whole chain. An empty response body from the
test endpoint with HTTP 200 means success; errors come back as a message string.

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
4. **Disable signups** — do this immediately after creating your account. The
   vault is publicly reachable, so until it is closed anyone who finds the URL
   can register on it.

   ```bash
   sed -i 's/^SIGNUPS_ALLOWED=.*/SIGNUPS_ALLOWED=false/' .env
   docker compose up -d --force-recreate
   ```

   > Use `up -d --force-recreate`, **not** `docker compose restart`. `restart`
   > reuses the existing container with its original environment and silently
   > ignores `.env` changes — you would believe signups were closed while they
   > stayed open.

   Verify by asserting the behaviour rather than trusting the setting. A closed
   instance answers `400`:

   ```bash
   docker exec vaultwarden printenv SIGNUPS_ALLOWED     # expect: false
   curl -sS -o /dev/null -w '%{http_code}\n' -X POST \
     https://vaultwarden.alimunee.com/identity/accounts/register \
     -H 'Content-Type: application/json' \
     -d '{"email":"probe@example.com","masterPasswordHash":"x","key":"x","kdf":0,"kdfIterations":600000}'
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

# Confirm the admin token reached the container as an intact PHC hash
docker exec vaultwarden printenv ADMIN_TOKEN

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

