# Monitoring & Management Services

## Overview

Services for system monitoring, container management, infrastructure oversight, and secrets management.

## System Monitoring

### Monitoring Services
- **Uptime Kuma** - Uptime monitoring & status page ([📖](../../services/kuma/documentation.md))
- **Beszel** - Lightweight system & Docker monitoring ([📖](../../services/beszel/documentation.md))
- **Checkmate** - Uptime & infrastructure monitoring ([📖](../../services/checkmate/documentation.md))
- **Glance** - System dashboard & monitoring ([📖](../../services/glance/documentation.md))

## Container Management

### Management Platforms
- **Dockge** - Docker container management ([📖](../../services/dockge/documentation.md))
- **Dozzle** - Real-time Docker log viewer ([📖](../../services/dozzle/documentation.md))
- **Komodo** - Infrastructure management platform ([📖](../../services/komodo/documentation.md))
- **Watchtower** - Automated container updates ([📖](../../services/watchtower/documentation.md))

## Secrets Management

### Security Services
- **Infisical** - Secrets & environment management ([📖](../../services/infisical/documentation.md))

## Monitoring Architecture

### Status Dashboards

#### Uptime Kuma Configuration
- **HTTP Monitors**: All web-accessible services
- **Ping Monitors**: Critical infrastructure components
- **Port Monitors**: Database and internal services
- **Status Pages**: Public and internal status pages

#### Glance Dashboard Features
- **Service Status**: Real-time service availability
- **System Metrics**: CPU, memory, disk usage
- **Quick Links**: Direct access to all services

## Management Workflows

### Container Updates with Watchtower

#### Update Strategy
```yaml
# Watchtower configuration
environment:
  - WATCHTOWER_SCHEDULE=0 0 4 * * *  # Daily at 4 AM
  - WATCHTOWER_NOTIFICATIONS=shoutrrr
  - WATCHTOWER_NOTIFICATION_URL=http://ntfy:8888/watchtower
  - WATCHTOWER_CLEANUP=true
```

#### Update Process
1. **Scheduled Check**: Daily scan for image updates
2. **Image Pull**: Download new container images
3. **Service Stop**: Gracefully stop running containers
4. **Container Update**: Deploy new container versions
5. **Health Check**: Verify service functionality
6. **Notification**: Send update status via ntfy
7. **Cleanup**: Remove old container images

### Infrastructure Management with Komodo
- **Multi-Server Management**: Manage multiple Docker hosts
- **Resource Monitoring**: CPU, memory, disk across servers
- **Service Deployment**: Deploy services across infrastructure
- **Log Aggregation**: Centralized logging from all servers

### Container Management with Dockge
- **Visual Interface**: Web-based stack management
- **Compose Editor**: Built-in Docker Compose editor
- **Log Viewing**: Real-time container log viewing
- **Resource Monitoring**: Container resource usage

### Log Management with Dozzle
- **Real-time Streaming**: Live log viewing from all containers
- **Search & Filter**: Fuzzy search and regex filtering
- **Container Actions**: Start, stop, restart containers from UI
- **Multi-user Auth**: Simple file-based authentication
- **Container Grouping**: Organize containers with custom labels

### Advanced Monitoring with Checkmate
- **Infrastructure Monitoring**: Server hardware and performance metrics
- **Multi-protocol Support**: HTTP/HTTPS, TCP, ICMP, DNS monitoring
- **Incident Management**: Automated alerting and escalation
- **Status Pages**: Public incident communication
- **Performance Analytics**: Response time tracking and trends

## Secrets Management with Infisical

### Secret Organization
```
Infisical Projects:
├── homelab-production/
│   ├── core-infrastructure/    # Traefik, Cloudflared secrets
│   ├── authentication/         # Zitadel, OAuth secrets
│   ├── databases/             # Database passwords
│   ├── ai-services/           # API keys (Gemini, etc.)
│   ├── media-stack/      # *arr stack API keys
│   └── monitoring/            # Monitoring service tokens
```

### Security Features
- **Encryption**: End-to-end encryption for all secrets
- **Access Control**: Role-based access to secrets
- **Audit Logging**: Complete audit trail of secret access
- **Rotation**: Automated secret rotation capabilities
- **Sync**: Automatic environment variable synchronization

## Monitoring Integration

### Health Checks
```bash
# Standard health check patterns
curl -f https://service.alimunee.com/health
curl -f https://service.alimunee.com/api/health
curl -f https://service.alimunee.com/ping
```

### Alert Configuration

#### Uptime Kuma Monitors
- **HTTP Monitors**: 30-second intervals for web services
- **Ping Monitors**: 60-second intervalsinfrastructure
- **Port Monitors**: 120-second intervals for databases

#### Alert Thresholds
- **Response Time**: Alert if > 5 seconds
- **Downtime**: Alert after 2 failed checks
- **Certificate Expiry**: Alert 30 days before expiration
- **Disk Space**: Alert at 85% usage

---

*For detailed monitoring and management service configuration, refer to individual service documentation[troubleshooting.md](troubleshooting.md)*
