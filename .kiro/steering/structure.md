# Project Structure

## Repository Organization

```
/HOMELAB/
├── configs/                    # System configuration files
│   ├── deploy-configs-fedora.sh   # Fedora-specific deployment script
│   ├── docker/                     # Docker daemon configs
│   ├── network/                    # Network interface configs
│   ├── nfs/                        # NFS export definitions
│   ├── scripts/                    # Monitoring scripts
│   ├── security/                   # SSH, fail2ban configs
│   ├── snapper/                    # Btrfs snapshot configs
│   ├── system/                     # Core system files (fstab, hosts)
│   └── systemd/                    # Service and timer files
├── docs/                       # Documentation
│   ├── docker/                     # Docker infrastructure docs (numbered 00-12)
│   ├── system/                     # System-specific docs
│   └── todo.md                    # Project checklist
└── services/                   # Docker service definitions
    ├── [service-name]/
    │   ├── docker-compose.yml     # Service definition
    │   ├── .env                   # Environment variables (if needed)
    │   └── documentation.md       # Service-specific docs
    └── ...
```

## Service Directory Conventions

### Standard Service Structure
Each service follows this pattern:
```
services/[service-name]/
├── docker-compose.yml          # Required: Service definition
├── documentation.md            # Required: Setup and usage docs
├── .env                        # Optional: Environment variables
└── stack.env                   # Optional: Stack-wide variables
```

### Docker Compose Standards
- **Networks**: Always use `proxy` network for web services, plus service-specific internal networks
- **Volumes**: Mount to `/storage/data/[service-name]/` directory structure for service data
- **Labels**: Include Traefik labels for web services with proper routing rules
- **Health Checks**: Implement for all services
- **Restart Policy**: Use `unless-stopped` for production services
- **Environment Variables**: Use .env files for sensitive data, document all variables

*For complete Docker Compose standards, see [docs/docker/03_core-infrastructure.md](docs/docker/03_core-infrastructure.md)*
*For network architecture details, see [docs/docker/01_docker-networks.md](docs/docker/01_docker-networks.md)*

## Configuration Management

### System Configs (`configs/`)
- **Centralized**: All system configurations in one location
- **Deployment**: Use `deploy-configs-fedora.sh` for automated deployment
- **Backup**: Always backup existing configs before deployment
- **Validation**: Test configurations before applying system-wide

### Service Configs (`services/`)
- **Environment Variables**: Use `.env` files for sensitive data
- **Documentation**: Each service must have `documentation.md`
- **Compose Files**: Follow Docker Compose best practices
- **Resource Limits**: Define appropriate CPU/memory limits

## Storage Conventions

### Storage Conventions
- **Data**: `/storage/data/[service]/` for ALL service configurations and databases (SSD)
- **Media**: `/storage/media/` for media files (HDD)
- **Photos**: `/storage/Immich/` for photo storage (HDD)
- **Cloud Files**: `/storage/nextcloud/` for Nextcloud user data (HDD)
- **Shared**: `/storage/shared/` for netwok shared files (nfs HDD)

*For complete storage architecture, see [docs/docker/02_storage-volumes.md](docs/docker/02_storage-volumes.md)*

## Documentation Standards

### Service Documentation (`documentation.md`)
Required sections:
1. **Purpose**: What the service does and its role in the homelab
2. **Configuration**: Environment variables, ports, domains, and key settings
3. **Dependencies**: Required services (databases, networks, external services)
4. **Setup**: Deployment instructions and initial configuration
5. **Usage**: How to access and use (URLs, admin interfaces)
6. **Integration**: SSO setup, notification configuration, monitoring
7. **Troubleshooting**: Common issues and solutions
8. **Backup**: Data backup procedures and restore steps

### Documentation Standards
- Include configuration tables for key settings
- Document all external access URLs and internal ports
- Include health check commands and verification steps

*For complete documentation standards, see individual service documentation in `/services/[service-name]/documentation.md`*
*For Docker infrastructure documentation, see [docs/docker/00_README.md](docs/docker/00_README.md)*

## Naming Conventions

### Services
- **Directory**: Lowercase, hyphenated (e.g., `uptime-kuma`)
- **Container**: Underscore format (e.g., `uptime_kuma`)
- **Subdomain**: Hyphenated (e.g., `uptime.alimunee.com`)

### Files
- **Configs**: Descriptive names matching system files
- **Scripts**: Action-based naming (e.g., `btrfs-smart-monitor.sh`)
- **Documentation**: Topic-based (e.g., `storage.md`, `security.md`)

### Networks
- **External**: `proxy`, `db_network`
- **Internal**: `[service]_internal` (e.g., `nextcloud_internal`)

## Development Workflow

### Adding New Services
1. Create service directory in `services/`
2. Write `docker-compose.yml` following standards
3. Create `.env` file if needed
4. Write `documentation.md`
5. Test deployment and functionality
6. Update main documentation

### Modifying Configurations
1. Backup existing configuration
2. Test changes in development
3. Update documentation
4. Deploy using deployment scripts
5. Verify functionality

### Monitoring Integration
- Add health checks to all services
- Configure ntfy notifications using appropriate topics (system-alerts, homelab-alerts, monitoring, etc.)
- Include service in Uptime Kuma monitoring
- Configure Watchtower labels for update management

*For complete monitoring setup, see [docs/docker/10_monitoring-management.md](docs/docker/10_monitoring-management.md)*
*For notification configuration, see [docs/docker/06_notifications-smtp.md](docs/docker/06_notifications-smtp.md)*
