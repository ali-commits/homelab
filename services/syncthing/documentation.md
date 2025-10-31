# Syncthing

## Purpose
Syncthing is a continuous file synchronization program that synchronizes files between two or more computers in real time, safely, securely, and without the cloud. It provides decentralized file sync with end-to-end encryption and conflict resolution.

## Configuration

| Variable | Description                   | Default          | Required |
| -------- | ----------------------------- | ---------------- | -------- |
| PUID     | User ID for file permissions  | 1000             | Yes      |
| PGID     | Group ID for file permissions | 1000             | Yes      |
| TZ       | Timezone                      | America/New_York | Yes      |

### Ports
- **8384**: Web UI (HTTPS via Traefik)
- **22000/tcp**: TCP file transfers
- **22000/udp**: QUIC file transfers
- **21027/udp**: Local discovery broadcasts

### Domains
- **External**: https://sync.alimunee.com
- **Internal**: http://syncthing:8384

## Dependencies
- **Networks**: proxy (for Traefik routing)
- **Storage**: /storage/syncthing/ (sync data), /storage/data/syncthing/config (configuration)

## Setup

1. **Deploy the service**:
   ```bash
   cd services/syncthing
   docker compose up -d
   ```

2. **Initial configuration**:
   - Access https://sync.alimunee.com
   - Complete initial setup wizard
   - Configure device name and folders
   - Set up authentication (Settings > GUI > GUI Authentication User/Password)

3. **Add devices**:
   - Go to Actions > Show ID to get device ID
   - On other devices, add this device using the ID
   - Accept connection requests in the web UI

4. **Configure folders**:
   - Add folders to sync in the web UI
   - Set folder paths relative to /var/syncthing/data in container
   - Configure sharing with other devices

## Usage

### Web Interface
- **URL**: https://sync.alimunee.com
- **Features**: Device management, folder configuration, sync status, logs

### Adding New Devices
1. Install Syncthing on target device
2. Get device ID from Actions > Show ID
3. Add device in web UI under Remote Devices
4. Accept connection on target device
5. Share folders as needed

### Folder Management
- **Local Path**: Maps to /storage/syncthing/ on host
- **Container Path**: /var/syncthing/data
- **Permissions**: Managed by PUID/PGID (1000:1000)

## Integration

### Monitoring
- **Health Check**: Built-in REST API health endpoint
- **Uptime Kuma**: Monitor https://sync.alimunee.com
- **ntfy Topic**: `homelab-alerts` for sync issues

### Notifications
Configure in Syncthing web UI:
- Settings > Actions > Add Action
- Use webhook to ntfy: `http://ntfy:8888/homelab-alerts`

## Troubleshooting

### Common Issues

1. **Connection Issues**:
   ```bash
   # Check container logs
   docker compose logs -f syncthing

   # Verify ports are accessible
   netstat -tulpn | grep -E "(8384|22000|21027)"
   ```

2. **Permission Problems**:
   ```bash
   # Fix ownership of sync directory
   sudo chown -R 1000:1000 /storage/syncthing/
   sudo chown -R 1000:1000 /storage/data/syncthing/
   ```

3. **Sync Conflicts**:
   - Check web UI for conflict files (.sync-conflict-*)
   - Review folder settings for ignore patterns
   - Verify device connectivity status

4. **Performance Issues**:
   ```bash
   # Monitor resource usage
   docker stats syncthing

   # Check sync progress
   curl -X GET "http://localhost:8384/rest/db/status?folder=default"
   ```

### Debug Commands
```bash
# View detailed logs
docker compose logs -f syncthing

# Check configuration
docker exec syncthing cat /var/syncthing/config/config.xml

# Test connectivity
docker exec syncthing curl -s http://localhost:8384/rest/system/ping

# Monitor sync status
docker exec syncthing curl -s http://localhost:8384/rest/system/status
```

## Backup

### Configuration Backup
```bash
# Backup Syncthing configuration
sudo tar -czf syncthing-config-$(date +%Y%m%d).tar.gz -C /storage/data/syncthing config/

# Restore configuration
sudo tar -xzf syncthing-config-YYYYMMDD.tar.gz -C /storage/data/syncthing/
sudo chown -R 1000:1000 /storage/data/syncthing/config/
docker compose restart syncthing
```

### Data Backup
- Syncthing data is automatically synchronized across devices
- Additional backup via Btrfs snapshots of /storage/syncthing/
- Consider excluding large media files from sync and backup separately

### Recovery Steps
1. Restore configuration from backup
2. Restart Syncthing service
3. Re-establish device connections
4. Verify folder sync status
5. Resolve any conflicts that arise during recovery
