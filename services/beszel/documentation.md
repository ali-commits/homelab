# Beszel - System Monitoring

## Purpose

Beszel is a lightweight, self-hosted system monitoring solution that provides real-time monitoring of system resources, Docker containers, and network statistics. It offers a clean web interface with historical graphs, alerting capabilitind minimal resource usage. Beszel complements Uptime Kuma by providing detailed system metrics rather than just service availability.

## Configuration

### Environment Variables

| Variable     | Description                  | Default                    | Required |
| ------------ | ---------------------------- | -------------------------- | -------- |
| BESZEL_TOKEN | Agent authentication token   | -                          | Yes      |
| BESZEL_KEY   | Agent public key             | -                          | Yes      |
| TZ           | Timezone                     | America/New_York           | No       |
| LISTEN       | Agent listen address/socket  | /beszel_socket/beszel.sock | No       |
| HUB_URL      | Hub URL for agent connection | http://localhost:8090      | No       |

### Ports and Access

- **Web Interface**: `monitoring.alimunee.com` (port 8090)
- **Internal Communication**: Unix socket between hub and agent

### Storage Locations

- **Hub Data**: `/storage/data/beszel/` (configuration, database)
- **Agent Data**: `/storage/data/beszel/agent/` (agent configuration)
- **Socket**: `/storage/data/beszel/socket/` (Unix socket for communication)

## Dependencies

### Required Services
- **Docker**: For container stats monitoring
- **Traefik**: For reverse proxy and SSL termination

### Required Networks
- **proxy**: For web interface access through Traefik

### System Requirements
- Docker socket access for container monitoring
- Host network mode for agent (system stats collection)

## Setup

### 1. Initial Deployment

```bash
cd services/beszel
docker compose up -d
```

### 2. First-Time Configuration

1. **Access the web interface**: Navigate to `https://monitoring.alimunee.com`
2. **Create admin account**: Set up your initial admin user
3. **Generate agent credentials**:
   - Go to Settings → Agents
   - Click "Add Agent"
   - Copy the generated token and public key

### 3. Configure Agent Authentication

Update the `.env` file with the generated credentials:

```bash
# Edit .env file
BESZEL_TOKEN=your_generated_token_here
BESZEL_KEY=your_generated_public_key_here
```

### 4. Restart Agent

```bash
docker compose restart beszel-agent
```

### 5. Add Agent in Web Interface

1. In the Beszel web interface, go to Settings → Agents
2. Add a new agent with:
   - **Name**: `homelab-server`
   - **Host/IP**: `/beszel_socket/beszel.sock` (Unix socket path)
   - **Port**: Leave empty for Unix socket

## Usage

### Web Interface Features

- **Dashboard**: Real-time system metrics overview
- **Historical Graphs**: CPU, memory, disk, network usage over time
- **Container Stats**: Docker container resource usage
- **Alerts**: Configurable thresholds for system metrics
- **Multi-host Support**: Monitor multiple servers from one interface

### Key Metrics Monitored

- **System**: CPU usage, memory usage, disk space, network I/O
- **Docker**: Container CPU, memory, network, and disk usage
- **Storage**: Disk usage for `/storage` filesystem
- **Network**: Interface statistics and bandwidth usage

### Alert Configuration

1. Go to Settings → Alerts
2. Configure thresholds for:
   - CPU usage (recommended: >80% for 5 minutes)
   - Memory usage (recommended: >90% for 5 minutes)
   - Disk space (recommended: >85%)
   - Network connectivity

## Integration

### Monitoring Integration

- **Uptime Kuma**: Add Beszel web interface monitoring
  - URL: `https://monitoring.alimunee.com`
  - Type: HTTP(s)
  - Expected Status: 200

### Notification Integration

Beszel supports various notification channels:
- **Email**: SMTP configuration in settings
- **Discord**: Webhook integration
- **Slack**: Webhook integration
- **Telegram**: Bot token and chat ID
- **ntfy**: Push notifications to ntfy topics

#### ntfy Integration Example

1. In Beszel settings, add ntfy notification:
   - **Type**: ntfy
   - **URL**: `https://ntfy.alimunee.com/monitoring-alerts`
   - **Token**: Your ntfy access token (if authentication enabled)

### SSO Integration

Currently, Beszel does not support OIDC/SSO integration. Authentication is handled through built-in user management.

## Troubleshooting

### Common Issues

#### Agent Not Connecting

**Symptoms**: Agent shows as offline in web interface

**Solutions**:
```bash
# Check agent logs
docker compose logs beszel-agent

# Verify socket permissions
ls -la /storage/data/beszel/socket/

# Restart agent
docker compose restart beszel-agent
```

#### Missing Container Stats

**Symptoms**: Docker containers not showing in interface

**Solutions**:
```bash
# Verify Docker socket mount
docker exec beszel-agent ls -la /var/run/docker.sock

# Check agent permissions
docker compose logs beszel-agent | grep -i docker
```

#### High Memory Usage

**Symptoms**: Beszel consuming excessive memory

**Solutions**:
- Reduce data retention period in settings
- Limit number of monitored containers
- Check for memory leaks in logs

### Health Check Commands

```bash
# Check service status
docker compose ps

# Test hub health endpoint
curl -f http://localhost:8090/api/health

# Test agent health
docker exec beszel-agent /agent health

# Verify socket communication
docker exec beszel ls -la /beszel_socket/
```

### Log Analysis

```bash
# Hub logs
docker compose logs beszel

# Agent logs
docker compose logs beszel-agent

# Follow logs in real-time
docker compose logs -f
```

## Backup

### Data to Backup

- **Configuration**: `/storage/data/beszel/` (hub database and settings)
- **Agent Config**: `/storage/data/beszel/agent/` (agent configuration)

### Backup Commands

```bash
# Create backup directory
mkdir -p /storage/backups/beszel/$(date +%Y%m%d)

# Backup hub data
cp -r /storage/data/beszel/ /storage/backups/beszel/$(date +%Y%m%d)/

# Backup docker-compose configuration
cp docker-compose.yml .env /storage/backups/beszel/$(date +%Y%m%d)/
```

### Restore Procedure

```bash
# Stop services
docker compose down

# Restore data
cp -r /storage/backups/beszel/YYYYMMDD/beszel/ /storage/data/

# Restore configuration
cp /storage/backups/beszel/YYYYMMDD/docker-compose.yml .
cp /storage/backups/beszel/YYYYMMDD/.env .

# Start services
docker compose up -d
```

## Security Considerations

- **Network Isolation**: Agent uses host network mode (required for system stats)
- **Socket Access**: Docker socket mounted read-only
- **Authentication**: Token-based authentication between hub and agent
- **Web Interface**: Protected by Traefik SSL termination
- **Data Encryption**: All web traffic encrypted via HTTPS

## Performance Impact

- **CPU Usage**: Minimal (<1% on modern systems)
- **Memory Usage**: ~50-100MB for hub, ~20-50MB for agent
- **Disk Usage**: Depends on retention settings (typically <1GB)
- **Network Usage**: Minimal internal communication via Unix socket

## Maintenance

### Regular Tasks

- **Weekly**: Review alert thresholds and adjust as needed
- **Monthly**: Clean up old data if retention is manual
- **Quarterly**: Update container images via Watchtower

### Update Procedure

Updates are handled automatically by Watchtower, but manual updates can be performed:

```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d
```
