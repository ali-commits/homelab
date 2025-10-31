# Notifications & SMTP Infrastructure

## Overview

Centralized notification and email delivery services providing push notifications and SMTP relay functionality for all homelab services.

## Services

### ntfy - Push Notification Service
- **Purpose**: Real-time push notifications for system alerts
- **Port**: 8888
- **Domain**: notification.alimunee.com
- **Documentation**: [📖](../../services/ntfy/documentation.md)

### Postfix - SMTP Relay Server
- **Purpose**: Centralized email delivery via Brevo upstream
- **Port**: 25 (internal)
- **Network**: mail_network
- **Upstream**: Brevo SMTP servers (smtp-relay.brevo.com:587)
- **Documentation**: [📖](../../services/postfix/documentation.md)

## ntfy Topic Structure

| Topic              | Purpose                        | Services                             |
| ------------------ | ------------------------------ | ------------------------------------ |
| **system-alerts**  | System-wide issues             | System monitoring scripts            |
| **homelab-alerts** | General service alerts         | Most services                        |
| **monitoring**     | Service monitoring alerts      | Uptime Kuma                          |
| **security**       | Security-related notifications | Fail2ban, security services          |
| **maintenance**    | Maintenance notifications      | System maintenance                   |
| **watchtower**     | Container update notifications | Watchtower                           |
| **media**          | Media stack alerts             | Prowlarr, Radarr, Sonarr, Jellyseerr |

## SMTP Integration

### Standard SMTP Settings
Services connect to the SMTP relay using these settings:

| Setting            | Value                    | Description                    |
| ------------------ | ------------------------ | ------------------------------ |
| **SMTP Host**      | `postfix`                | Container name on mail_network |
| **SMTP Port**      | `25`                     | Standard SMTP port (internal)  |
| **Authentication** | None                     | Relay handles upstream auth    |
| **From Address**   | `[service]@alimunee.com` | Service-specific sender        |

### Services Using SMTP

| Service           | From Address              | Purpose                                |
| ----------------- | ------------------------- | -------------------------------------- |
| **Zitadel**       | `auth@alimunee.com`       | Authentication emails, password resets |
| **Infisical**     | `secrets@alimunee.com`    | Security alerts, invitations           |
| **Firefly III**   | `budget@alimunee.com`     | Financial reports, notifications       |
| **Nextcloud**     | `cloud@alimunee.com`      | Sharing notifications, updates         |
| **Uptime Kuma**   | `monitoring@alimunee.com` | Service alerts, status updates         |
| **BookLore**      | `books@alimunee.com`      | Book delivery, notifications           |
| **Paperless-ngx** | `docs@alimunee.com`       | Document processing, sharing           |

### Network Configuration

Services requiring email functionality must be connected to the `mail_network`:

```yaml
networks:
  - proxy              # For web access
  - mail_network       # For SMTP relay access
  - [service]_internal # For internal service communication
```

## Integration Examples

### Adding Email to a Service

1. **Add to mail_network**:
   ```yaml
   networks:
     - proxy
     - mail_network  # Add this network
   ```

2. **Configure SMTP Settings**:
   ```yaml
   environment:
     - SMTP_HOST=postfix
     - SMTP_PORT=25
     - SMTP_FROM=[service]@alimunee.com
     - SMTP_FROM_NAME=[Service Name]
   ```

### Adding ntfy Notifications

```bash
# Send notification
curl -d "Message content" http://ntfy:8888/homelab-alerts

# With priority and tags
curl -H "Title: Alert Title" -H "Priority: 4" -H "Tags: warning,gear" \
     -d "Alert message" http://ntfy:8888/system-alerts
```

---

*For detailed configuration, refer to individual service documentation: [ntfy](../../services/ntfy/documentation.md) and [postfix](../../services/postfix/documentation.md)*
