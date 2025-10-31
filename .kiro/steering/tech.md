# Technology Stack

## Operating System
- **Base OS**: Fedora 42 Server
- **Package Manager**: DNF (replaces APT commands)
- **Filesystem**: Btrfs with compression and snapshots

## Container Infrastructure
- **Runtime**: Docker with NVIDIA runtime for GPU acceleration
- **Networks**: Custom bridge networks (proxy, db_network, service-specific internal networks)
- **Storage**: Bind mounts to `/storage/` directory structure

*For detailed network architecture, see [docs/docker/01_docker-networks.md](docs/docker/01_docker-networks.md)*
*For complete storage configuration, see [docs/docker/02_storage-volumes.md](docs/docker/02_storage-volumes.md)*

## Core Services
- **Proxy**: Traefik v3.3 with Cloudflare tunnels
- **Database**: PostgreSQL 16-alpine, Redis, MongoDB
- **Monitoring**: Uptime Kuma, ntfy notifications
- **GPU**: NVIDIA GTX 1070 for transcoding and ML
- **Remote Access**: Tailscale VPN with on-demand subnet routing

*For complete service reference, see [docs/docker/00_README.md](docs/docker/00_README.md)*

## Essential Commands

### Service Management
```bash
# Check all containers with health status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"

# View service logs
docker compose -f services/[service]/docker-compose.yml logs -f

# Restart service stack
cd services/[service] && docker compose down && docker compose up -d
```

### System Monitoring
```bash
# Monitor GPU usage (Jellyfin transcoding + Immich ML)
watch -n 1 nvidia-smi

# Check Btrfs health and usage
sudo btrfs fi usage /storage
```

### Network Management
```bash
# Create required Docker networks
docker network create proxy
docker network create db_network
docker network create mail_network

# Tailscale remote access (on-demand)
sudo tailscale up --advertise-routes=192.168.1.0/24 --accept-routes  # Enable subnet routing
sudo tailscale up --advertise-routes="" --accept-routes=false        # Disable for security
tailscale status                                                     # Check connection status
```

*For complete operational procedures, see [docs/docker/12_operations.md](docs/docker/12_operations.md)*
*For troubleshooting commands, see [docs/docker/11_troubleshooting.md](docs/docker/11_troubleshooting.md)*

## Development Patterns
- Use environment files (.env) for sensitive configuration
- Implement healthchecks for all services
- Use specific image tags, avoid 'latest' in production
- Implement proper restart policies (unless-stopped)
- Include Traefik labels for web-accessible services
- Use internal networks for service isolation
- For GPU ML workloads: Use CUDA-specific images

*For complete development guidelines, see [.kiro/steering/service-development.md](.kiro/steering/service-development.md)*
*For Docker Compose standards, see [.kiro/steering/structure.md](.kiro/steering/structure.md)*
