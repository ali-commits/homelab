# Docker Networks

## Overview

Docker network architecture providing service isolation, routing, and secure communication between conta
# Network Topology

```
Internet → Cloudflare → Cloudflared → Traefik → Services
                                                    ↓
                                    Zitadel (SSO)  |  Postfix (SMTP) → Brevo
```

## Core Networks

### External Networks

| Network          | Purpose                    | Services                         |
| ---------------- | -------------------------- | -------------------------------- |
| **proxy**        | Main reverse proxy network | All web-accessible services      |
| **db_network**   | Database connections       | PostgreSQL containers + services |
| **mail_network** | SMTP relay network         | Postfix + services needing email |

### Internal Networks

| Network                 | Purpose                        | Services                                                 |
| ----------------------- | ------------------------------ | -------------------------------------------------------- |
| **cloudreve_internal**  | Cloudreve services isolation   | Cloudreve app + database + redis                         |
| **firefly_internal**    | Firefly III services isolation | Firefly III + database + redis + cron                    |
| **immich_internal**     | Immich services isolation      | Immich app + database + redis + ML                       |
| **infisical_internal**  | Infisical services isolation   | Infisical + database + redis                             |
| **nextcloud_internal**  | Nextcloud services isolation   | Nextcloud + database + redis + cron                      |
| **onlyoffice_internal** | OnlyOffice services isolation  | OnlyOffice + database + redis + rabbitmq                 |
| **n8n_internal**        | N8N services isolation         | N8N + database                                           |
| **komodo_internal**     | Komodo services isolation      | Komodo core + periphery + mongo                          |
| **zitadel_internal**    | Zitadel services isolation     | Zitadel + login + database                               |
| **linkwarden_internal** | Linkwarden services isolation  | Linkwarden + database                                    |
| **booklore_internal**   | BookLore services isolation    | BookLore + MariaDB database                              |
| **karakeep_internal**   | Karakeep services isolation    | Karakeep + database + Meilisearch                        |
| **paperless_internal**  | Paperless services isolation   | Paperless-ngx + Paperless-GPT + Tika + Gotenberg + Redis |

## Network Configuration Patterns

### Standard DNS Configuration
All services use standardized DNS servers for reliable name resolution:
```yaml
dns:
  - 8.8.8.8             # Google DNS (primary)
  - 1.1.1.1             # Cloudflare DNS (secondary)
```

### Web-Accessible Services
```yaml
dns:
  - 8.8.8.8
  - 1.1.1.1
networks:
  - proxy              # Required for Traefik routing
```

### Database-Backed Services
```yaml
dns:
  - 8.8.8.8
  - 1.1.1.1
networks:
  - proxy              # Web access via Traefik
  - db_network         # Shared database access
  - [service]_internal # Service-specific isolation
```

### Email-Enabled Services
```yaml
dns:
  - 8.8.8.8
  - 1.1.1.1
networks:
  - proxy              # Web access
  - mail_network       # SMTP relay access
  - [service]_internal # Internal communication
```

### Multi-Container Stacks
```yaml
dns:
  - 8.8.8.8
  - 1.1.1.1
networks:
  - proxy                 # External web access
  - [service]_internal    # Internal service communication
  - db_network           # Database access (if shared)
  - mail_network         # Email access (if needed)
```

## DNS Configuration

### Standardized DNS Servers
All containers use consistent DNS configuration to ensure reliable name resolution:

- **8.8.8.8** (Google DNS) - Primary DNS server
- **1.1.1.1** (Cloudflare DNS) - Secondary DNS server

### Benefits
- **Consistent Resolution**: Bypasses potential local DNS issues
- **Reliability**: Multiple DNS providers ensure high availability
- **Performance**: Fast, globally distributed DNS infrastructure
- **Security**: Trusted DNS providers with security features

### DNS Troubleshooting
```bash
# Test DNS resolution inside container
docker exec [container] nslookup google.com
docker exec [container] dig @8.8.8.8 example.com

# Check container DNS configuration
docker inspect [container] | jq '.[0].HostConfig.Dns'
```

## Network Security

### Security Patterns
- **Web services** must be on `proxy` network for Traefik routing
- **Database containers** should be on both `db_network` and service-specific internal networks
- **Internal service communication** uses service-specific networks
- **No direct host network access** unless absolutely required (AdGuard DNS)

### Network Isolation
- Each multi-container service has its own internal network
- Services only connect to networks they actually need
- Database access is controlled via network membership
- SMTP access is limited to services that need email functionality

## Network Management

### Creating Networks
```bash
# Create core networks
docker network create proxy --driver bridge
docker network create db_network --driver bridge
docker network create mail_network --driver bridge

# Create service-specific networks (handled by docker-compose)
docker network create [service]_internal --driver bridge
```

### Network Inspection
```bash
# List all networks
docker network ls

# Inspect specific networks
docker network inspect proxy
docker network inspect db_network
docker network inspect mail_network

# Check service network assignments
docker inspect [container] | jq '.[0].NetworkSettings.Networks | keys'
```

### Network Troubleshooting
```bash
# Test connectivity between containers
docker exec [container1] nc -zv [container2] [port]

# Check DNS resolution
docker exec [container] nslookup [service-name]

# Verify network membership
docker network inspect [network] | jq '.[0].Containers'
```

## Service Network Assignments

### Core Infrastructure
- **Traefik**: proxy
- **Cloudflared**: proxy
- **AdGuard**: proxy (plus host network for DNS)
- **Watchtower**: proxy

### Authentication & Communication
- **Zitadel**: proxy, zitadel_internal
- **Postfix**: mail_network

### Monitoring & Management
- **Uptime Kuma**: proxy
- **ntfy**: proxy
- **Glance**: proxy
- **Dockge**: proxy
- **Komodo**: proxy, komodo_internal
- **Infisical**: proxy, infisical_internal, mail_network

### Media Services
- **Jellyfin**: proxy
- **Radarr**: proxy
- **Sonarr**: proxy
- **Prowlarr**: proxy
- **Bazarr**: proxy
- **qBittorrent**: proxy
- **Jellyseerr**: proxy
- **Flood**: proxy
- **Flaresolverr**: proxy
- **Kavita**: proxy
- **BookLore**: proxy, booklore_internal, mail_network

### Productivity Services
- **Nextcloud**: proxy, nextcloud_internal
- **Immich**: proxy, immich_internal
- **AFFiNE**: proxy
- **OnlyOffice**: proxy, onlyoffice_internal
- **Cloudreve**: proxy, cloudreve_internal
- **N8N**: proxy, n8n_internal
- **Linkwarden**: proxy, linkwarden_internal
- **Karakeep**: proxy, karakeep_internal, db_network
- **Syncthing**: proxy
- **IT-Tools**: proxy
- **Stirling PDF**: proxy
- **Paperless-ngx**: proxy, paperless_internal, db_network, mail_network
- **Paperless-GPT**: proxy, paperless_internal
- **Firefly III**: proxy, firefly_internal

---

*For detailed network configuration, refer to individual service documentation in `/services/[service-name]/documentation.md`*
