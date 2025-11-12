# Tugtainer

## Purpose

Tugtainer is a self-hosted Docker container management tool that automates container updates with a web UI. It provides a user-friendly alternative to Watchtower, offering manual control, automatic update scheduling, multi-host management, and notifications.

## Key Features

- **Web Interface**: Clean dashboard to view and manage container states
- **Update Management**: Manual or scheduled automatic updates (disabled by default)
- **Multi-Host Support**: Manage remote Docker hosts from a single interface
- **Notification System**: Alerts when updates are available
- **Individual Controls**: Customize update behavior per container
- **Compose Support**: Handles Docker Compose dependencies properly

## Configuration

| Variable | Description | Default | Required |
| -------- | ----------- | ------- | -------- |
| HOSTNAME | Hostname for the application | tugtainer.alimunee.com | No |
| LOG_LEVEL | Logging level (DEBUG, INFO, WARNING, ERROR) | warning | No |
| TZ | Timezone for scheduling | Asia/Kuala_Lumpur | No |
| OIDC_ENABLED | Enable OpenID Connect authentication | false | No |
| OIDC_WELL_KNOWN_URL | OIDC discovery URL | - | If SSO enabled |
| OIDC_CLIENT_ID | OIDC client ID | - | If SSO enabled |
| OIDC_CLIENT_SECRET | OIDC client secret | - | If SSO enabled |
| OIDC_REDIRECT_URI | OIDC redirect URI | - | If SSO enabled |

## Dependencies

### Required Services

- Traefik (reverse proxy)

### Required Networks

- `proxy` - For web access through Traefik

### System Requirements

- Docker socket access (read-only)
- Persistent volume for database and configuration

## Setup

### 1. Create Data Directory

```bash
sudo mkdir -p /storage/data/tugtainer
sudo chown -R 1000:1000 /storage/data/tugtainer
```

### 2. Deploy Service

```bash
cd /HOMELAB/services/tugtainer
docker compose up -d
```

### 3. Initial Configuration

1. Access the web UI at `https://tugtainer.alimunee.com`
2. Set up initial password (stored encrypted in `/tugtainer/password_hash`)
3. Configure update schedule in Settings (default: cron `0 0 * * *` - daily at midnight)
4. Enable update checks for desired containers

## Usage

### Access

- **Web UI**: <https://tugtainer.alimunee.com>
- **Default Auth**: Password-based (set on first access)

### Container Management

1. **View Containers**: Main dashboard shows all containers with current status
2. **Enable Checking**: Toggle per-container to check for updates
3. **Enable Updates**: Toggle per-container to allow automatic updates
4. **Manual Update**: Click update button for immediate update
5. **View Images**: Separate tab shows available images and pruning options

### Update Schedule

- Configure in Settings → Schedule
- Uses cron expression format
- Default: `0 0 * * *` (daily at midnight)
- Automatic updates disabled by default for safety

### Multi-Host Management

To manage remote Docker hosts:

1. Deploy Tugtainer Agent on remote host (see Remote Hosts section)
2. In UI: Menu → Hosts → Add Host
3. Provide agent URL and shared secret
4. Enable/disable per-host in hosts list

### Notifications

Configure notification URL in Settings using Apprise format:

- **ntfy**: `ntfy://tugtainer.alimunee.com/homelab-alerts`
- **Email**: `mailto://user:password@smtp.server`
- **Multiple**: Comma-separated URLs

## Integration

### SSO (Zitadel) - Optional

Tugtainer supports OIDC authentication starting from v1.6.0.

**Environment Variables:**

```yaml
environment:
  - OIDC_ENABLED=true
  - OIDC_WELL_KNOWN_URL=https://sso.alimunee.com/.well-known/openid-configuration
  - OIDC_CLIENT_ID=[from-Zitadel]
  - OIDC_CLIENT_SECRET=[from-Zitadel]
  - OIDC_REDIRECT_URI=https://tugtainer.alimunee.com/auth/callback
  - OIDC_SCOPES=openid profile email
```

**Zitadel Configuration:**

1. Create new application in Zitadel
2. Set redirect URI: `https://tugtainer.alimunee.com/auth/callback`
3. Enable scopes: openid, profile, email
4. Copy client ID and secret to environment variables

### Remote Hosts (Agent Deployment)

To manage containers on remote hosts:

**1. Deploy Agent on Remote Host:**

```bash
docker run -d -p 9413:8001 \
    --name=tugtainer-agent \
    --restart=unless-stopped \
    -e AGENT_SECRET="[generate-secure-secret]" \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    quenary/tugtainer-agent:latest
```

**2. Generate Secret:**

```bash
openssl rand -base64 32
```

**3. Add Host in Tugtainer UI:**

- Navigate to Menu → Hosts
- Click "Add Host"
- Enter host name, URL (<http://remote-host:9413>), and shared secret
- Enable the host

### Monitoring Integration

- Built-in health check endpoint: `/api/public/health`
- Configure Uptime Kuma to monitor the service
- Set up ntfy notifications for update alerts

### Socket Proxy (Optional)

For enhanced security without direct Docker socket access:

**Deploy Socket Proxy:**

```yaml
services:
  socket-proxy:
    image: lscr.io/linuxserver/socket-proxy:latest
    container_name: tugtainer-socket-proxy
    environment:
      - CONTAINERS=1
      - IMAGES=1
      - POST=1
      - INFO=1
      - PING=1
      - NETWORKS=1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - tugtainer_internal
```

**Update Tugtainer:**

```yaml
environment:
  - DOCKER_HOST=tcp://socket-proxy:2375
```

## Maintenance

### View Logs

```bash
docker compose -f /HOMELAB/services/tugtainer/docker-compose.yml logs -f
```

### Backup Data

Backup `/storage/data/tugtainer` directory:

- `tugtainer.db` - Container settings and schedules
- `password_hash` - Encrypted password

### Update Application

Watchtower will automatically update the container when new versions are available.

Manual update:

```bash
cd /HOMELAB/services/tugtainer
docker compose pull
docker compose up -d
```

### Reset Password

```bash
docker exec -it tugtainer rm /tugtainer/password_hash
docker restart tugtainer
# Access web UI to set new password
```

### Prune Images

Use the web UI:

1. Navigate to Images tab
2. Click "Prune Unused Images"
3. Or enable automatic pruning in Settings

## Important Notes

### Safety Considerations

- **NOT recommended for production environments**
- Automatic updates disabled by default
- Always maintain backups before enabling auto-updates
- Use caution with "latest" tags
- Review container dependencies before updating

### Best Practices

1. **Test Updates**: Enable checking first, review changes before enabling auto-updates
2. **Compose Stacks**: Tugtainer handles dependencies automatically (com.docker.compose.depends_on)
3. **Exclude Containers**: Disable checking for critical infrastructure (Traefik, databases)
4. **Scheduled Updates**: Run during low-traffic hours
5. **Notifications**: Configure alerts to stay informed
6. **Self-Container**: Tugtainer can update itself (handle with care)

### Update Process

1. **Check Phase**: Queries registries for new image versions
2. **Preparing**: Groups containers by compose projects
3. **Updating**: Pulls new images and recreates containers
4. **Post-Update**: Prunes old images if configured
5. **Notification**: Sends summary via configured channels

## Troubleshooting

### Container Won't Update

- Verify container has "Check Enabled" and "Update Enabled" toggled
- Check logs for permission errors
- Ensure image tag is not pinned to specific version
- Verify internet connectivity for image pulls

### Health Check Failing

```bash
docker exec tugtainer wget -O- http://localhost:80/api/public/health
```

### Database Locked

```bash
docker compose down
docker compose up -d
```

### Remote Host Connection Issues

- Verify agent is running: `curl http://remote-host:9413/api/public/health`
- Check firewall allows port 9413
- Verify shared secret matches
- Test network connectivity between hosts

## Related Services

- **Watchtower**: Automatic container updates (no UI)
- **Dockge**: Docker Compose manager
- **Portainer**: Full Docker management suite
- **Komodo**: Infrastructure management and monitoring

## References

- [GitHub Repository](https://github.com/Quenary/tugtainer)
- [Docker Hub](https://hub.docker.com/r/quenary/tugtainer)
- [Documentation](https://github.com/Quenary/tugtainer/blob/main/readme.md)
