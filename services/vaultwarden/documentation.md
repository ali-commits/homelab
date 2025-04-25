# Vaultwarden

**Purpose**: Self-hosted password manager compatible with Bitwarden clients

| Configuration Setting | Value                         |
| --------------------- | ----------------------------- |
| Image                 | `vaultwarden/server:latest`   |
| Memory Limits         | `1GB max, 256MB minimum`      |
| Timezone              | `Asia/Kuala_Lumpur`           |
| PUID/PGID             | `1000`                        |

**Configuration Details**:

| Configuration     | Details                                   |
|-------------------|-------------------------------------------|
| External Access   | vault.alimunee.com                        |
| Admin Interface   | Disabled (empty ADMIN_TOKEN)              |
| Signups           | Disabled for security                     |
| Invitations       | Enabled                                   |
| WebSockets        | Enabled for live sync                     |
| TLS               | Disabled internally (handled by Cloudflare)|
| Password Security | High iterations (600,000)                 |

**Volume Mappings**:

| Volume        | Path                          |
| ------------- | ----------------------------- |
| Data          | `/storage/data/vaultwarden/data` |

**Network Settings**:

| Setting                 | Value                 |
| ----------------------- | --------------------- |
| Web Interface Port      | `80`                  |
| WebSocket Port          | `3012`                |
| Domain                  | `vault.alimunee.com`  |
| Network                 | `proxy`               |

**Security Considerations**:

- User registration is disabled by default
- Admin interface is disabled by default
- High password iteration count (600,000) for enhanced security
- Runs as non-root user (PUID/PGID 1000)
- Data is stored in an encrypted format
- WebSocket support is properly configured for real-time updates

**Usage Instructions**:

1. Access Vaultwarden at vault.alimunee.com
2. Use any Bitwarden client (mobile, desktop, browser extension) to connect
3. Point clients to https://vault.alimunee.com
4. To create users, enable the admin interface temporarily or use invitations

**Maintenance**:

- Regularly backup the data volume
- Update the container periodically for security patches
- Monitor container logs for any unusual activity
- Consider enabling email notifications for important security events
