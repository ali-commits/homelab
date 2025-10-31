# Dozzle - Docker Log Viewer

**Purpose**: Real-time Docker container log viewer with web interface for monitoring and debugging containerized applications.

## Service Information

- **Container Image**: `amir20/dozzle:v8.8.3`
- **External URL**: https://logs.alimunee.com
- **Internal Port**: 8080
- **Purpose**: Web-based Docker log monitoring and container management

## Features

- 🔍 **Real-time log streaming** from all Docker containers
- 🎯 **Fuzzy search and regex filtering** for log analysis
- 🔄 **Container actions** - start, stop, restart containers directly from UI
- 👥 **Multi-user authentication** with simple file-based auth
- 🏷️ **Container grouping** and custom naming via labels
- 📱 **Responsive design** for mobile and desktop access
- 🔒 **Security-focused** with read-only Docker socket access

## Configuration

### Environment Variables

| Variable              | Description                                   | Default | Required |
| --------------------- | --------------------------------------------- | ------- | -------- |
| DOZZLE_AUTH_PROVIDER  | Authentication method (simple, forward-proxy) | none    | No       |
| DOZZLE_ENABLE_ACTIONS | Allow container start/stop/restart actions    | false   | No       |
| DOZZLE_HOSTNAME       | Hostname for multi-host identification        | auto    | No       |
| DOZZLE_LEVEL          | Log level (trace, debug, info, warn, error)   | info    | No       |
| DOZZLE_FILTER         | Filter containers by label or name            | none    | No       |

### Volume Mounts
- `/var/run/docker.sock:/var/run/docker.sock:ro` - Docker socket (read-only)
- `/storage/data/dozzle:/data` - User authentication and configuration data

### Network Configuration
- **Internal Port**: 8080
- **External Domain**: logs.alimunee.com
- **Network**: proxy (for Traefik routing)

## Dependencies

- **Docker**: Requires access to Docker socket for log reading
- **Traefik**: For reverse proxy and SSL termination
- **Storage**: `/storage/data/dozzle` for user data persistence

## Setup Instructions

### 1. Create Required Directories
```bash
# Create data directory
sudo mkdir -p /storage/data/dozzle
sudo chown ali:ali /storage/data/dozzle
```

### 2. Configure Authentication (Optional)
Create a users file for simple authentication:
```bash
# Create users.yml for authentication
cat > /storage/data/dozzle/users.yml << EOF
users:
  admin:
    name: "Administrator"
    password: "\$2a\$10\$your-bcrypt-hashed-password"
    email: "admin@alimunee.com"
EOF
```

Generate bcrypt password hash:
```bash
# Using htpasswd (if available)
htpasswd -bnBC 10 "" your-password | tr -d ':\n'

# Or using online bcrypt generator
# https://bcrypt-generator.com/
```

### 3. Deploy Service
```bash
cd /HOMELAB/services/dozzle
docker compose up -d
```

### 4. Verify Deployment
```bash
# Check container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"

# Check logs
docker logs dozzle

# Test health endpoint
curl -f http://localhost:8080/api/healthcheck
```

## Usage

### Accessing the Interface
- Navigate to: https://logs.alimunee.com
- Login with configured credentials (if authentication enabled)

### Key Features

#### Log Viewing
- **Real-time streaming**: Logs update automatically as containers generate output
- **Search and filter**: Use fuzzy search or regex patterns to find specific log entries
- **Multi-container view**: Monitor multiple containers simultaneously
- **Log levels**: Filter by different log levels (info, warn, error, debug)

#### Container Management
- **Container actions**: Start, stop, restart containers directly from the interface
- **Container grouping**: Organize containers by custom groups using labels
- **Health monitoring**: View container health status and resource usage

#### Advanced Features
- **Download logs**: Export log files for offline analysis
- **Live stats**: Monitor container resource usage in real-time
- **Custom labels**: Use Docker labels for container organization

### Container Labels for Enhanced Experience

Add these labels to your services for better Dozzle integration:

```yaml
services:
  your-service:
    labels:
      # Custom container name in Dozzle
      - "dev.dozzle.name=My Custom Service"
      # Group containers together
      - "dev.dozzle.group=media-stack"
      # Hide from Dozzle (if needed)
      - "dev.dozzle.enable=false"
```

## Integration

### Monitoring Integration
- **Uptime Kuma**: Monitor Dozzle availability at https://logs.alimunee.com
- **ntfy notifications**: Configure alerts for container failures or restarts

### Security Integration
- **Zitadel SSO**: Can be configured for enterprise authentication
- **Traefik**: Handles SSL termination and routing
- **Network isolation**: Runs on proxy network only

## Troubleshooting

### Common Issues

1. **Cannot see container logs**:
   ```bash
   # Check Docker socket permissions
   ls -la /var/run/docker.sock

   # Verify Dozzle can access Docker
   docker exec dozzle ls -la /var/run/docker.sock
   ```

2. **Authentication not working**:
   ```bash
   # Check users.yml format
   cat /storage/data/dozzle/users.yml

   # Verify file permissions
   ls -la /storage/data/dozzle/
   ```

3. **Container actions disabled**:
   - Ensure `DOZZLE_ENABLE_ACTIONS=true` is set
   - Check Docker socket has write permissions (remove :ro if needed)

4. **Traefik routing issues**:
   ```bash
   # Check Traefik logs
   docker logs traefik | grep dozzle

   # Verify network connectivity
   docker network inspect proxy
   ```

### Health Check Commands
```bash
# Check Dozzle health
docker exec dozzle /dozzle healthcheck

# Monitor container logs
docker logs -f dozzle

# Test API endpoint
curl -f https://logs.alimunee.com/api/healthcheck
```

## Security Considerations

- **Docker socket access**: Mounted read-only by default for security
- **Container actions**: Enable only if needed, provides container control
- **Authentication**: Use simple auth or forward-proxy for access control
- **Network isolation**: Runs on proxy network only
- **No new privileges**: Security option prevents privilege escalation

## Backup Procedures

### Data Backup
```bash
# Backup user configuration
sudo cp -r /storage/data/dozzle /backup/dozzle-$(date +%Y%m%d)

# Backup service configuration
cp -r /HOMELAB/services/dozzle /backup/services/dozzle-$(date +%Y%m%d)
```

### Restore Procedures
```bash
# Restore user data
sudo cp -r /backup/dozzle-YYYYMMDD/* /storage/data/dozzle/
sudo chown -R ali:ali /storage/data/dozzle

# Restart service
cd /HOMELAB/services/dozzle
docker compose down && docker compose up -d
```

## Performance Optimization

### Resource Limits
Consider adding resource limits for production use:

```yaml
services:
  dozzle:
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
        reservations:
          memory: 128M
          cpus: '0.25'
```

### Log Retention
- Dozzle doesn't store logs permanently - it reads from Docker's log driver
- Configure Docker log rotation to manage disk usage:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

## Useful Commands

```bash
# View all container logs through Dozzle API
curl -s https://logs.alimunee.com/api/containers

# Check Dozzle configuration
docker exec dozzle env | grep DOZZLE

# Monitor Dozzle performance
docker stats dozzle

# Restart Dozzle service
cd /HOMELAB/services/dozzle
docker compose restart
```

## Links

- **GitHub**: https://github.com/amir20/dozzle
- **Docker Hub**: https://hub.docker.com/r/amir20/dozzle
- **Documentation**: https://dozzle.dev/
- **Live Demo**: https://dozzle.dev/demo
