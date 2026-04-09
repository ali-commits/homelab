# Core Infrastructure Services

## Overview

Foundation services providing routing, networking, DNS, and system-level functionality.

## Services

### Traefik - Reverse Proxy & Load Balancer
- **Purpose**: Routes external traffic to internal services
- **Ports**: 80, 443, 8080 (dashboard)
- **Dashboard**: Port 8080 (`--api.insecure=true`, no Traefik Host rule)
- **Documentation**: [📖](../../services/traefik/documentation.md)

### Cloudflared - Cloudflare Tunnel Service
- **Purpose**: Secure tunnel to Cloudflare for external access
- **Network**: proxy
- **Documentation**: [📖](../../services/cloudflared/documentation.md)

### AdGuard - DNS Filtering & Ad Blocking
- **Purpose**: Network-wide DNS filtering and ad blocking
- **Ports**: 53 (DNS), 3333, 8989 (web interface)
- **Domain**: adguard.alimunee.com
- **Documentation**: [📖](../../services/adguard/documentation.md)

## Network Architecture

### Docker Networks

| Network                | Purpose                    | Services                         |
| ---------------------- | -------------------------- | -------------------------------- |
| **proxy**              | Main reverse proxy network | All web-accessible services      |
| **db_network**         | Database connections       | PostgreSQL containers + services |
| **[service]_internal** | Service isolation          | Multi-container service stacks   |

### Network Topology
```
Internet → Cloudflare → Cloudflared → Traefik → Services
                                                    ↓
                                    Zitadel (SSO)  |  Postfix (SMTP) → Brevo
```

## Storage Architecture

### Storage Structure
```
/storage/
├── data/               → System & service data (NVMe SSD)
├── media/             → Media library (HDD)
├── Immich/            → Photo storage (HDD)
├── nextcloud/         → Nextcloud storage (HDD)
├── paperless-ngx/     → Document storage (HDD)
├── syncthing/         → Synchronized files (HDD)
└── shared/            → Shared between services (HDD)
```

## GPU Configuration (NVIDIA GTX 1070)

**Hardware Acceleration Status**: ✅ **FUNCTIONAL**

- **Driver**: NVIDIA 580.95.05 with CUDA 13.0
- **Container Toolkit**: nvidia-container-toolkit (latest)
- **Docker Runtime**: nvidia-container-runtime set as default
- **Services**: Jellyfin (transcoding), Immich (ML)

### GPU Services
- **Jellyfin**: Hardware transcoding (NVENC/NVDEC)
- **Immich**: Machine learning acceleration (CUDA)

## Docker Configuration

### DNS Configuration
All services are configured with standardized DNS servers for reliable name resolution:
- **Primary DNS**: 8.8.8.8 (Google DNS)
- **Secondary DNS**: 1.1.1.1 (Cloudflare DNS)

This ensures consistent DNS resolution across all containers, bypassing potential issues with local DNS configuration.

### System Configuration Files
- **System**: `/etc/docker/daemon.json` (NVIDIA runtime)
- **Homelab**: [`/HOMELAB/configs/docker/daemon.json`](../../configs/docker/daemon.json) (logging, networks)

---

*For detailed service configuration, refer to individual service documentation in `/services/[service-name]/documentation.md`*
