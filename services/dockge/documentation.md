# Dockge - Docker Stack Manager

A fancy, easy-to-use and reactive self-hosted docker compose.yaml stack-oriented manager.

## Service Information

- **Container Image**: `louislam/dockge:1`
- **External URL**: https://dockge.alimunee.com
- **Internal Port**: 5001
- **Purpose**: Web-based Docker Compose stack management interface

## Features

- 🧑‍💼 Manage your `compose.yaml` files (Create/Edit/Start/Stop/Restart/Delete)
- ⌨️ Interactive Editor for `compose.yaml`
- 🦦 Interactive Web Terminal
- 🏪 Convert `docker run ...` commands into `compose.yaml`
- 📙 File based structure - Won't kidnap your compose files
- 🚄 Reactive - Real-time progress and terminal output
- 🐣 Easy-to-use & fancy UI

## Configuration

### Directory Structure
```
/HOMELAB/services/              # Main stacks directory (managed by Dockge)
/storage/data/dockge/           # Dockge application data
```

### Environment Variables
- `DOCKGE_STACKS_DIR=/opt/stacks` - Location where Dockge manages stacks (mapped to `/HOMELAB/services`)

### Volume Mounts
- `/var/run/docker.sock` - Docker socket for container management
- `/storage/data/dockge:/app/data` - Application data storage
- `/HOMELAB/services:/opt/stacks` - Direct management of existing homelab services
- `/usr/bin/docker:/usr/bin/docker:ro` - Docker CLI access
- `/usr/libexec/docker/cli-plugins:/usr/libexec/docker/cli-plugins:ro` - Docker compose plugin

## Setup Instructions

### 1. Create Required Directories
```bash
# Create data directory
sudo mkdir -p /storage/data/dockge
sudo chown ali:ali /storage/data/dockge
```

### 2. Deploy Service
```bash
cd /HOMELAB/services/dockge
docker compose up -d
```

### 3. Access Web Interface
- Navigate to: https://dockge.alimunee.com
- First time setup will require creating an admin account

## Managing Existing Stacks

### Automatic Discovery
Since Dockge is configured to use `/HOMELAB/services` as its stacks directory, all your existing services are automatically available for management:

1. **Scan for stacks** in Dockge web interface:
   - Click the dropdown menu in top-right corner
   - Select "Scan Stacks Folder"
   - All existing services should appear in the list

2. **Direct management**: You can now start, stop, restart, and edit any service directly through the Dockge interface

### Benefits of This Configuration
- **No migration needed**: All existing services are immediately available
- **Unified management**: Single interface for all Docker stacks
- **File-based structure**: Compose files remain in their original locations
- **Git integration**: Changes made through Dockge are reflected in your git repository
- **Backup compatibility**: Existing backup procedures continue to work## Security Considerations

- **Docker socket access**: Dockge has full Docker control - restrict access appropriately
- **File system access**: Can read/write to `/opt/stacks` - ensure proper permissions
- **Zitadel integration**: Uncomment SSO middleware once Zitadel is configured
- **Network isolation**: Runs on `proxy` network for Traefik access only

## Troubleshooting

### Common Issues

1. **Permission denied errors**:
   ```bash
   sudo chown -R ali:ali /opt/stacks /storage/data/dockge
   ```

2. **Stack not appearing**:
   - Use "Scan Stacks Folder" button in Dockge UI
   - Check that the service has a `docker-compose.yml` file in its directory
   - Ensure directory structure matches: `/HOMELAB/services/{service-name}/docker-compose.yml`

3. **Service conflicts**:
   - Before starting a service through Dockge, ensure it's not already running via traditional docker compose
   - Use `docker ps` to check for existing containers

4. **Traefik routing issues**:
   ```bash
   docker logs traefik | grep dockge
   docker network inspect proxy
   ```

## Useful Commands

```bash
# Check Dockge logs
docker logs dockge

# Restart Dockge
cd /HOMELAB/services/dockge
docker compose restart

# View stacks directory (now same as services directory)
ls -la /HOMELAB/services/

# Check Docker socket permissions
ls -la /var/run/docker.sock
```

## Integration with Homelab

- **Monitoring**: Add health checks to Uptime Kuma
- **Backups**: Existing backup procedures for `/HOMELAB/services` continue to work
- **Updates**: Managed through Watchtower
- **Notifications**: Configure ntfy integration for stack events
- **Git integration**: Changes made through Dockge are reflected in the git repository

## Workflow Benefits

This configuration provides several advantages:

1. **No disruption**: Existing services continue to work without modification
2. **Web interface**: Easy management of all services through a single interface
3. **File preservation**: All compose files remain in their original locations
4. **Git compatibility**: Changes sync with your version control system
5. **Terminal access**: Built-in web terminal for advanced operations
6. **Real-time feedback**: Live progress updates and log streaming

## Links

- **GitHub**: https://github.com/louislam/dockge
- **Docker Hub**: https://hub.docker.com/r/louislam/dockge
- **Documentation**: https://github.com/louislam/dockge#readme
