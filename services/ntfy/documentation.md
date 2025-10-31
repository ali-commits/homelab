# NTFY

**Purpose**: Self-ho**Available Topics**:
- `system-alerts` - System-wide alerts (backups, monitoring)
- `homelab-alerts` - General homelab notifications
- `monitoring` - Service monitoring alerts
- `security` - Security-related notifications
- `maintenance` - Maintenance notifications
- `watchtower` - Container update notifications
- `media` - Media stack alerts (Prowlarr, Radarr, Sonarr, Jellyseerr)ub-sub notification service

📖 **For comprehensive documentation, see [System Notifications Guide](/HOMELAB/docs/system/notifications.md)**

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | notification.alimunee.com            |
| Internal Access   | http://localhost:8888                 |
| Authentication    | None (open access)                    |
| Cookie Domain     | Not explicitly configured             |
| TLS               | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin   | Not applicable                        |

**Security**:

- Basic authentication enabled
- Access control for topics
- Behind reverse proxy configuration

**Network Configuration**:

- Web Interface: Port 8888:80
- Domain: notification.alimunee.com

**Available Topics**:
- `system-alerts` - System-wide alerts (backups, monitoring)
- `homelab-alerts` - General homelab notifications
- `monitoring` - Service monitoring alerts
- `security` - Security-related notifications
- `maintenance` - Maintenance notifications

**Quick Test**:
```bash
# Local test
curl -d "Testing ntfy service" http://localhost:8888/test

# External test with advanced features
curl \
  -H "Title: Test Alert" \
  -H "Priority: 4" \
  -H "Tags: test,gear" \
  -d "Testing notification.alimunee.com" \
  https://notification.alimunee.com/homelab-alerts
```
