# Agent Guidelines for Homelab Infrastructure

Comprehensive homelab on Fedora 42 Server with Docker services, GPU acceleration, and automated monitoring.

## Product Overview

**Hardware**: AMD Threadripper 2920X, 32GB RAM, NVIDIA GTX 1070, Btrfs storage
**Core Services**: Media stack (*arr + Jellyfin), Cloud storage (Nextcloud, Immich), Security (Zitadel SSO, AdGuard), Infrastructure (Traefik, Watchtower)
### Key Features
- **GPU Acceleration**: NVIDIA GTX 1070 with NVENC for ML and video encoding
- **Storage**: Multi-tier Btrfs, automated snapshots via Snapper, and Kopia backup to S3 backups
- **Monitoring**: Comprehensive system monitoring with ntfy notifications, SMART health checks, Btrfs integrity
- **Security**: Multi-layered security with SSH hardening, fail2ban, SELinux, network segmentation, SSO
- **Automation**: Watchtower for container updates, automated backups, maintenance scripts

### Hardware Specifications
- **CPU**: AMD Ryzen Threadripper 2920X
- **Memory**: 32GB DDR4
- **GPU**: NVIDIA GeForce GTX 1070
- **Storage**: 1TB NVMe (system) + 3.6TB HDD (data)
- **Network**: Static IP (192.168.1.2/24) with Cloudflare tunnel integration and Taiscale VPN

### Target Users
Self-hosted homelab for personal/family use with emphasis on automation, performance optimization, data protection, and secure remote access.

## Technology Stack

- **OS**: Fedora 43 Server (DNF package manager)
- **Container**: Docker with NVIDIA runtime
- **Proxy**: Traefik v3.3 + Cloudflare tunnels
- **Networks**: `proxy`, `db_network`, `mail_network`, `[service]_internal`
- **GPU**: NVIDIA GTX 1070 for transcoding and ML workloads

*Architecture details: [docs/docker/01_docker-networks.md](docs/docker/01_docker-networks.md), [docs/docker/02_storage-volumes.md](docs/docker/02_storage-volumes.md)*

## Project Structure

```
/HOMELAB/
├── configs/           # System configs (deploy-configs-fedora.sh, docker/, network/, security/)
├── docs/docker/       # Infrastructure docs (numbered 00-12)
└── services/          # Docker service definitions
    └── [service-name]/
        ├── docker-compose.yml  # Required
        ├── documentation.md    # Required
        └── .env
```

### Storage Conventions
- `/storage/data/[service]/` - Service configs/databases
storage/media/` - Media files (HDD)
- `/storage/Immich/` - Photos (HDD)
- `/storage/nextcloud/` - Cloud files (HDD)
- `/storage/shared/` - NFS shared files (HDD)

### Naming Conventions
- **Directory**: `uptime-kuma`
- **Container**: `uptime_kuma`
- **Subdomain**: `uptime.alimunee.com`
- **Networks**: `proxy`, `db_network`, `[service]_internal`

## Service Development Workflow

### 1. Research Phase (MANDATORY)
1. **Context7**: `mcp_Context7_resolve_library_id` → `mcp_Context7_get_library_docs`
2. **Perplexity**: Search "[service-name] docker compose setup 2025"
3. **Existing Services**: Study similar services in `/services/` directory

### 2. Docker Compose Template
```yaml
services:
  [service-name]:
    image: [specific-tag-not-latest]
    container_name: [service_name]
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /storage/data/[service]/:/app/data
    dns:
      - 8.8.8.8                 # Google DNS (primary)
      - 1.1.1.1                 # Cloudflare DNS (secondary)
    networks:
      - proxy                   # For web-accessible services
      - [service]_internal      # For multi-container services
      - db_network              # If using shared database
      - mail_network            # If using SMTP relay
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.[service].rule=Host(`[service].alimunee.com`)"
      - "traefik.http.services.[service].loadbalancer.server.port=[port]"
      - "traefik.docker.network=proxy"
      - "com.centurylinklabs.watchtower.enable=true"
    healthcheck:
      # healthcheck

networks:
  proxy:
    external: true
  db_network:
    external: true
  mail_network:
    external: true
```

#### Environment File (.env) Standards
```bash
DB_HOST=postgres
DB_NAME=[service]_db
DB_USER=[service]_user
DB_PASSWORD=[generate-secure-password]

# Application Configuration
APP_KEY=[generate-app-specific-key] # if needed
APP_URL=https://[service].alimunee.com

# SMTP Configuration (if needed)
SMTP_HOST=postfix
SMTP_PORT=25
SMTP_FROM=[service]@alimunee.com

# External Integrations (if applicable)
SSO_CLIENT_ID=[from-Zitadel]
SSO_CLIENT_SECRET=[from-sso-provider]

# othere variables if needed like tokens, apis, etc...
```

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

## Common 404 Troubleshooting

### 1. Health Check Failures
```yaml
# ❌ WRONG - Non-existent endpoint
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]

# ✅ CORRECT - Test actual endpoint or remove
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/"]
```

### 2. TLS Configuration Conflicts
```yaml
# ❌ WRONG - Conflicts with Cloudflare
labels:
  - "traefik.http.routers.service.tls=true"

# ✅ CORRECT - Let Cloudflare handle TLS
labels:
  - "traefik.http.routers.service.rule=Host(`service.alimunee.com`)"
```

### 3. Router Name Conflicts
```yaml
# ✅ Use unique, descriptive names
labels:
  - "traefik.http.routers.linkwarden.rule=Host(`bookmarks.alimunee.com`)"
```

### 4. Missing Dependencies
Check official docs for ALL required services (databases, search engines, cache).

**Debug Steps**:
```bash
docker exec <container> curl -f http://localhost:3000/
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"
```

*Complete troubleshooting: [docs/docker/11_troubleshooting.md](docs/docker/11_troubleshooting.md)*

## Documentation Standards

### Required Sections in `documentation.md`
1. **Purpose** - Service role in homelab
2. **Configuration** - Environment variables table
3. **Dependencies** - Required services/networks
4. **Setup** - Deployment instructions
5. **Usage** - Access URLs, admin interfaces
6. **Integration** - SSO, SMTP, monitoring setup

### Configuration Table Format
```markdown
| Variable | Description       | Default  | Required |
| -------- | ----------------- | -------- | -------- |
| DB_HOST  | Database hostname | postgres | Yes      |
```

*Standards: [docs/docker/00_README.md](docs/docker/00_README.md)*

## Security & Development Standards

### Password Generation
```bash
openssl rand -base64 32                   # Secure passwords
echo "base64:$(openssl rand -base64 32)"  # Laravel APP_KEY
```

### Prohibited Practices
- **NEVER create deployment scripts** (deploy.sh, setup.sh)
- **NEVER use explicit TLS labels** (conflicts with Cloudflare)

## Development Workflow

### Adding New Services
1. Write `docker-compose.yml` following standards
2. Create `.env` file if needed
3. Write `documentation.md`
4. Test deployment and functionality
5. Update main documentation

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

## Testing and Validation

### Pre-Deployment Checklist
- [ ] Research service with Perplexity and/or Context7
- [ ] Review similar services for patterns
- [ ] Create docker-compose.yml following standards
- [ ] Generate secure passwords and keys (if needed) (generate all in one command)
- [ ] Create comprehensive .env file
- [ ] Write complete documentation.md
- [ ] Test configuration with getDiagnostics

### Post-Deployment Validation
- [ ] Container starts successfully
- [ ] wait for users feedback
- [ ] if these is issues accessing the service
  - [ ] Check health
  - [ ] Check if web interface accessible
  - [ ] Check database connectivity works
- [ ] SMTP relay functional (if applicable)
- [ ] Monitoring alerts configured
- [ ] Backup procedures tested
- [ ] after everything works prompt the user to start SSO integration (if applicable)


## Integration Patterns

### SSO (Zitadel)
1. Prompt user to create application in Zitadel
2. Configure OIDC settings
3. Test authentication
*Integration details: [docs/docker/04_authentication.md](docs/docker/04_authentication.md), [docs/docker/06_notifications-smtp.md](docs/docker/06_notifications-smtp.md), [docs/docker/10_monitoring-management.md](docs/docker/10_monitoring-management.md)*


### SMTP (Postfix)
1. Add `mail_network`
2. Set SMTP environment variables
3. Test email delivery




## Key Documentation References

- **Infrastructure**: `docs/docker/` (00-12 numbered files)
- **Service Configs**: `services/[service]/documentation.md`
- **System Configs**: `configs/`
- **Network Architecture**: `docs/docker/01_docker-networks.md`
- **Storage**: `docs/docker/02_storage-volumes.md`
- **Operations**: `docs/docker/12_operations.md`
