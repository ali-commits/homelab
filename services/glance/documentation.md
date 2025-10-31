# Glance Dashboard

## Purpose
Glance is a lightweight, highly customizable dashboard that displays your homelab services and feeds in a beautiful, streamlined interface. It provides a single pane of glass for monitoring service status, viewing RSS feeds, checking weather, and accessing all your self-hosted applications.

## Configuration

| Setting            | Value                     | Description                 |
| ------------------ | ------------------------- | --------------------------- |
| **Container Name** | `glance`                  | Main container name         |
| **Image**          | `glanceapp/glance:latest` | Official Glance image       |
| **Port**           | `8080`                    | Internal web interface port |
| **Domain**         | `glance.alimunee.com`     | External access URL         |
| **Config File**    | `./glance.yml`            | Dashboard configuration     |

### Key Features
- **Service Monitoring**: Monitor all homelab services with visual status indicators
- **RSS Feeds**: Display homelab news and updates from selfh.st, LinuxServer blog
- **Release Tracking**: Track updates for key services (Jellyfin, Immich, Nextcloud, etc.)
- **Weather Widget**: Local weather information
- **Calendar**: Built-in calendar widget
- **Docker Integration**: Monitor container status (requires Docker socket access)

## Dependencies
- **Networks**: `proxy` (for Traefik routing)
- **External Services**: None (self-contained)
- **Optional**: Docker socket for container monitoring

## Setup

1. **Deploy the service**:
   ```bash
   cd /HOMELAB/services/glance
   docker compose up -d
   ```

2. **Verify deployment**:
   ```bash
   docker compose logs glance
   curl -I http://localhost:8080
   ```

3. **Configure location and services**:
   - Edit `glance.yml` to update weather location
   - Modify service URLs to match your setup
   - Add/remove widgets as needed

## Usage

### Access Points
- **Internal**: http://localhost:8080
- **External**: https://glance.alimunee.com
- **Mobile Optimized**: Responsive design works well on mobile devices

### Widget Configuration
The dashboard is organized in three columns:
- **Left (Small)**: Calendar, weather, release tracking for key services
- **Center (Full)**: Service monitoring with status indicators (Infrastructure, Media, Productivity)
- **Right (Small)**: Docker container status, RSS feeds for homelab news

### Customization
- **Theme**: Light theme with blue primary color
- **Layout**: Modify column sizes and widget placement in `glance.yml`
- **Widgets**: Add/remove widgets based on your needs
- **Feeds**: Update RSS feeds to match your interests

## Integration

### Traefik Integration
- Automatic SSL via Cloudflare tunnels
- Route: `glance.alimunee.com`
- Health checks enabled for monitoring

### Service Monitoring
Configure monitor widgets for each service:
```yaml
- type: monitor
  title: Service Name
  url: https://service.alimunee.com
```

### Docker Container Monitoring
The dashboard includes Docker container monitoring. To enable full functionality, mount the Docker socket:
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

Configure containers with labels for better display:
```yaml
labels:
  glance.name: "Service Name"
  glance.icon: "si:service-icon"
  glance.url: "https://service.alimunee.com"
  glance.description: "Service description"
```

## Troubleshooting

### Common Issues
1. **Requests timing out**: Check DNS rate limits (Pi-hole/AdGuard)
2. **Broken layout**: Disable Dark Reader browser extension
3. **Config errors**: Validate YAML syntax in `glance.yml`

### Health Check Commands
```bash
# Check container status
docker compose ps

# View logs
docker compose logs -f glance

# Test web interface
curl -f http://localhost:8080 || echo "Service unavailable"

# Validate configuration
docker compose config
```

### Performance Monitoring
```bash
# Monitor resource usage
docker stats glance --no-stream

# Check response times
time curl -s http://localhost:8080 > /dev/null
```

## Backup

### Configuration Backup
```bash
# Backup configuration
cp services/glance/glance.yml backups/glance-config-$(date +%Y%m%d).yml

# Restore configuration
cp backups/glance-config-YYYYMMDD.yml services/glance/glance.yml
docker compose restart glance
```

### No Data Backup Required
Glance is stateless - all configuration is in `glance.yml`. No persistent data storage required.

## Updates

Watchtower automatically updates the container. Manual update:
```bash
cd /HOMELAB/services/glance
docker compose pull
docker compose up -d
```

## Security Notes
- Read-only configuration mount
- No privileged access required
- Lightweight with minimal attack surface
- All external access via Traefik with SSL