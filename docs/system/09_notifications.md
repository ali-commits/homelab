# Notification System

This document describes the homelab's notification system using ntfy, which provides real-time push notifications for system events, alerts, and status updates.

## Overview

The homelab uses [ntfy](https://ntfy.sh/) as a self-hosted notification service running in Docker. It provides multiple channels for different types of notifications and supports various client applications.

## Configuration

### Service Details
- **Service**: ntfy (Docker container)
- **Internal URL**: `http://localhost:8888`
- **External URL**: `https://notification.alimunee.com` (via Traefik)
- **Configuration**: `/storage/data/ntfy/etc/`
- **Cache**: `/storage/data/ntfy/cache/`

### Authentication
- **Default User**: `v`
- **Default Password**: `pass123`
- **Config File**: `/etc/default/notification-settings`

## Available Channels/Topics

| Topic           | Purpose                              | Used By                              | Priority | Description                             |
| --------------- | ------------------------------------ | ------------------------------------ | -------- | --------------------------------------- |
| `system-alerts` | System-wide alerts and notifications | Backup scripts, monitoring           | 2-5      | Critical system events                  |
| `system-status` | General homelab notifications        | Various services                     | 1-5      | General operational notifications       |
| `watchtower`    | Container update notifications       | Watchtower service                   | 2-4      | Docker image updates and failures       |
| `media`         | Media stack notifications            | Prowlarr, Radarr, Sonarr, Jellyseerr | 1-3      | Download status, new releases, requests |
| `Kuma`          | Uptime Kuma notifications            | Uptime Kuma                          | 5        | services and website status             |

## Client Access

### Web Interface
Access the ntfy web interface at:
- **Local**: `http://localhost:8888`
- **External**: `https://notification.alimunee.com`

### Mobile Apps
Download the ntfy mobile app:
- **Android**: [Google Play Store](https://play.google.com/store/apps/details?id=io.heckel.ntfy)
- **iOS**: [App Store](https://apps.apple.com/us/app/ntfy/id1625396347)

### Desktop Applications
- **Windows/macOS/Linux**: Use the web interface or third-party clients
- **Browser notifications**: Enable in the web interface settings

## Subscription Setup

### Subscribe to All Homelab Topics
To receive all homelab notifications, subscribe to these topics:

```bash
# Using the ntfy CLI tool
ntfy subscribe https://notification.alimunee.com/system-alerts
ntfy subscribe https://notification.alimunee.com/backup-status
ntfy subscribe https://notification.alimunee.com/homelab-alerts
ntfy subscribe https://notification.alimunee.com/maintenance
ntfy subscribe https://notification.alimunee.com/monitoring
ntfy subscribe https://notification.alimunee.com/security
ntfy subscribe https://notification.alimunee.com/watchtower
ntfy subscribe https://notification.alimunee.com/media
```

### Mobile App Configuration
1. Open the ntfy mobile app
2. Add a new subscription
3. Server: `https://notification.alimunee.com`
4. Topic: Choose from the available topics above
5. Authentication: Use the admin credentials if required

## Priority Levels

Notifications use these priority levels:

| Priority | Level   | Description           | Example Use Cases                      |
| -------- | ------- | --------------------- | -------------------------------------- |
| 1        | Min     | Lowest priority       | Debug information, verbose logs        |
| 2        | Low     | Success notifications | Successful backups, routine operations |
| 3        | Default | Normal notifications  | General status updates, maintenance    |
| 4        | High    | Important alerts      | Service warnings, partial failures     |
| 5        | Max     | Critical alerts       | System failures, security breaches     |

## Configuration Files

### Notification Settings
**File**: `/etc/default/notification-settings`
```bash
# Notification Service Settings
NTFY_URL="https://notification.alimunee.com"
NTFY_DEFAULT_TOPIC="system-alerts"
NTFY_DEFAULT_USER="admin"
NTFY_DEFAULT_PASS="pass123"
```

### Docker Compose
**File**: `/HOMELAB/services/ntfy/docker-compose.yml`
```yaml

services:
  ntfy:
    image: binwiederhier/ntfy
    container_name: ntfy
    restart: unless-stopped
    environment:
      - TZ=Asia/Kuala_Lumpur
    volumes:
      - /storage/data/ntfy/cache:/var/cache/ntfy
      - /storage/data/ntfy/etc:/etc/ntfy
    ports:
      - "8888:80"
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.ntfy.rule=Host(`notification.alimunee.com`)"
      - "traefik.http.routers.ntfy.entrypoints=web"
      - "traefik.http.services.ntfy.loadbalancer.server.port=80"
```

## Testing Notifications

### Command Line Testing
```bash
# Test basic notification
curl -X POST https://notification.alimunee.com/system-alerts \
    -H "Title: Test Alert" \
    -H "Priority: 3" \
    -H "Tags: test,homelab" \
    -d "This is a test notification from the homelab"

# Test with high priority
curl -X POST https://notification.alimunee.com/system-alerts \
    -H "Title: High Priority Test" \
    -H "Priority: 4" \
    -H "Tags: urgent,homelab" \
    -d "This is a high priority test notification"

# Test Watchtower notification
curl -X POST https://notification.alimunee.com/watchtower \
    -H "Title: Container Update" \
    -H "Priority: 2" \
    -H "Tags: docker,update" \
    -H "Tags: docker,watchtower" \
    -d "jellyfin:latest updated successfully"

# Test Media notification
curl -X POST http://localhost:8888/media \
    -u "admin:pass123" \
    -H "Title: Download Complete" \
    -H "Priority: 1" \
    -H "Tags: media,radarr" \
    -d "Movie downloaded: The Matrix (1999)"
```

### Script Testing
```bash
# Test backup notification function
sudo bash -c '
source /etc/default/notification-settings
NTFY_TOPIC="${NTFY_DEFAULT_TOPIC:-homelab-alerts}"

curl -s -X POST "$NTFY_URL/$NTFY_TOPIC" \
    -u "$NTFY_DEFAULT_USER:$NTFY_DEFAULT_PASS" \
    -H "Title: Backup Test" \
    -H "Priority: 3" \
    -H "Tags: backup,storage" \
    -d "Testing notification system from backup script"
'
```

## Service Management

### Docker Commands
```bash
# Check ntfy service status
docker ps | grep ntfy

# View ntfy logs
docker logs ntfy -f

# Restart ntfy service
docker restart ntfy

# Update ntfy service
cd /HOMELAB/services/ntfy
docker-compose pull
docker-compose up -d
```

### Service Health Check
```bash
# Check if ntfy is responding
curl -s http://localhost:8888/v1/health

# Test notification delivery
curl -X POST http://localhost:8888/test-topic \
    -H "Title: Health Check" \
    -d "ntfy service is operational"
```

## Security Considerations

### Access Control
- ntfy is accessible locally without authentication
- External access via Traefik requires HTTPS
- Consider implementing access tokens for production use

### Network Security
- Service runs on internal Docker network
- Only port 8888 is exposed to host
- External access controlled by Traefik rules

### Best Practices
- Use unique topics for different services
- Implement rate limiting for high-volume notifications
- Regular backup of ntfy configuration and cache
- Monitor notification delivery for critical alerts

## Troubleshooting

### Common Issues

#### Notifications Not Received
1. Check if ntfy service is running: `docker ps | grep ntfy`
2. Verify network connectivity: `curl http://localhost:8888/v1/health`
3. Check authentication credentials in scripts
4. Verify topic subscription in client app

#### Service Won't Start
1. Check Docker logs: `docker logs ntfy`
2. Verify volume mounts exist: `ls -la /storage/data/ntfy/`
3. Check port conflicts: `netstat -tulpn | grep 8888`
4. Restart Docker service: `sudo systemctl restart docker`

#### External Access Issues
1. Check Traefik configuration and logs
2. Verify DNS resolution for `ntfy.alimunee.com`
3. Test internal access first: `curl http://localhost:8888`
4. Check firewall rules and port forwarding

### Debug Commands
```bash
# Check ntfy configuration
docker exec ntfy cat /etc/ntfy/server.yml

# Test notification delivery
curl -v -X POST http://localhost:8888/debug-topic \
    -H "Title: Debug Test" \
    -d "Debug notification test"

# Monitor ntfy logs in real-time
docker logs ntfy -f --tail 50
```

## Monitoring Integration

### Uptime Kuma Integration
ntfy can be integrated with Uptime Kuma for service monitoring notifications:

1. Add ntfy webhook URL to Uptime Kuma notifications
2. Configure different topics for different service types
3. Set appropriate priority levels for alerts

### Custom Scripts
Example notification function for custom scripts:

```bash
#!/bin/bash

send_notification() {
    local title="$1"
    local message="$2"
    local topic="${3:-system-alerts}"
    local priority="${4:-3}"

    curl -s -X POST "http://localhost:8888/$topic" \
        -u "admin:pass123" \
        -H "Title: $title" \
        -H "Priority: $priority" \
        -H "Tags: homelab,custom" \
        -d "$message"
}

# Usage
send_notification "System Update" "System updated successfully" "maintenance" 2
```

---

## Container & Media Notifications

### Watchtower Notifications
**Topic**: `watchtower`
**Service**: Docker container updater
**Frequency**: On container updates or failures

| Event Type           | Priority | Example Message                         |
| -------------------- | -------- | --------------------------------------- |
| **Update Success**   | 2        | `Container updated: jellyfin:latest`    |
| **Update Failed**    | 4        | `Failed to update container: nextcloud` |
| **Multiple Updates** | 3        | `Updated 5 containers successfully`     |
| **Critical Failure** | 5        | `Watchtower service crashed`            |

### Media Stack Notifications
**Topic**: `media`
**Services**: Prowlarr, Radarr, Sonarr, Jellyseerr
**Frequency**: Real-time for downloads and requests

#### Notification Types by Service

**Prowlarr (Indexer Management)**:
- Indexer failures or warnings (Priority 4)
- New indexer added (Priority 2)
- Search errors (Priority 3)

**Radarr (Movies)**:
- Movie downloaded (Priority 2)
- Download failed (Priority 3)
- New movie added (Priority 1)
- Quality upgrade available (Priority 2)

**Sonarr (TV Shows)**:
- Episode downloaded (Priority 1)
- Season pack downloaded (Priority 2)
- Missing episode alerts (Priority 3)
- Series monitoring started (Priority 1)

**Jellyseerr (Requests)**:
- New media request (Priority 2)
- Request approved/denied (Priority 2)
- Request completed (Priority 1)
- User account issues (Priority 4)

### Configuration Examples

#### Watchtower Integration
```yaml
# docker-compose.yml for Watchtower
environment:
  - WATCHTOWER_NOTIFICATIONS=shoutrrr
  - WATCHTOWER_NOTIFICATION_URL=ntfy://admin:pass123@localhost:8888/watchtower
```

#### Media Stack Integration
Each service can be configured with webhook URLs:
```bash
# Example webhook URL for media services
http://admin:pass123@localhost:8888/media
```

---

*Last updated: 2025-06-25*
*Service status: ✅ Operational*
