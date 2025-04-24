# Docker Infrastructure Documentation

## Overview

This document details the Docker infrastructure setup powering our homelab environment. The infrastructure is designed with the following key principles:

- **Security**: Using Authentik for authentication and Cloudflare for secure access
- **Modularity**: Services are organized in isolated networks (proxy, database)
- **Monitoring**: Integrated monitoring and updates through Watchtower
- **Management**: Centralized management via Portainer
- **Service Discovery**: Traefik handles routing and service discovery

## Table of Contents

- [Docker Infrastructure Documentation](#docker-infrastructure-documentation)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Service Reference](#service-reference)
  - [File Structure](#file-structure)
  - [Docker Infrastructure](#docker-infrastructure)
  - [Initial Setup Instructions](#initial-setup-instructions)
    - [1. Environment Setup](#1-environment-setup)
    - [2. Network Setup](#2-network-setup)
  - [Network Topology](#network-topology)
    - [Network Configuration](#network-configuration)
    - [Persistent Volumes](#persistent-volumes)
  - [Detailed Service Documentation](#detailed-service-documentation)
    - [Portainer](#portainer)
    - [Cloudflared](#cloudflared)
    - [Traefik](#traefik)
    - [Authentik](#authentik)
    - [AdGuard](#adguard)
    - [NTFY](#ntfy)
    - [Watchtower](#watchtower)
    - [Uptime Kuma](#uptime-kuma)
    - [Jellyfin](#jellyfin)
    - [Media Management (\*arr stack)](#media-management-arr-stack)
      - [Radarr](#radarr)
      - [Sonarr](#sonarr)
      - [Prowlarr](#prowlarr)
      - [Bazarr](#bazarr)
      - [FlareSolverr](#flaresolverr)
      - [Jellyseerr](#jellyseerr)
    - [qBittorrent](#qbittorrent)
    - [Immich](#immich)
    - [Nextcloud](#nextcloud)
    - [Linkwarden](#linkwarden)
  - [Maintenance Procedures](#maintenance-procedures)
    - [Daily Operations](#daily-operations)
    - [Weekly Tasks](#weekly-tasks)
    - [Monthly Maintenance](#monthly-maintenance)
    - [Emergency Procedures](#emergency-procedures)
  - [Security and Auditing](#security-and-auditing)
    - [Security Best Practices](#security-best-practices)
    - [Security Auditing](#security-auditing)
    - [Monitoring and Alerting](#monitoring-and-alerting)

## Service Reference

| Service      | Port Mappings  | Networks        | Domain                    | Purpose                      |
| ------------ | -------------- | --------------- | ------------------------- | ---------------------------- |
| Portainer    | 8000, 9443     | proxy           | portainer.alimunee.com    | Container management         |
| Traefik      | 8080           | proxy           | traefik.alimunee.com      | Reverse proxy/Load balancer  |
| Authentik    | 9999:9000      | proxy           | auth.alimunee.com         | Authentication service       |
| AdGuard      | 53, 8989, 3333 | proxy           | adguard.alimunee.com      | DNS and ad blocking          |
| NTFY         | 8888:80        | proxy           | ntfy.alimunee.com         | Notification service         |
| Uptime Kuma  |                | proxy           | uptime.alimunee.com       | Monitoring and status page   |
| Jellyfin     | 8096           | proxy           | tv.alimunee.com           | Media streaming service      |
| Radarr       | 7878           | proxy           | radarr.alimunee.com       | Movie collection manager     |
| Sonarr       | 8989           | proxy           | sonarr.alimunee.com       | TV shows collection manager  |
| Prowlarr     | 9696           | proxy           | prowlarr.alimunee.com     | Indexer management           |
| Bazarr       | 6767           | proxy           | bazarr.alimunee.com       | Subtitle management          |
| Flaresolverr | 8191           | proxy           | flaresolverr.alimunee.com | Cloudflare bypass service    |
| Jellyseerr   | 5055           | proxy           | request.alimunee.com      | Media request management     |
| qBittorrent  | 8088, 6881     | proxy           | qbit.alimunee.com         | Download client              |
| Gotify       | 8087:80        | proxy           | notify.alimunee.com       | Push notification service    |
| Immich       | 2283           | proxy           | photos.alimunee.com       | Photo management system      |
| Nextcloud    | 80             | proxy           | cloud.alimunee.com        | File storage & collaboration |
| Linkwarden   | 3000           | proxy, internal | links.alimunee.com        | Bookmark & link manager      |

## File Structure

```plaintext
/storage
|-- Immich
|   |-- database
|   |-- model-cache
|   |-- uploads
|-- data
|   |-- adguard
|   |-- authentik
|   |-- bazarr
|   |-- jellyfin
|   |-- jellyseerr
|   |-- ntfy
|   |-- portainer
|   |-- prowlarr
|   |-- qbittorrent
|   |-- radarr
|   |-- sonarr
|   |-- tdarr
|   |-- traefik
|   `-- uptime-kuma
|-- media
|   |-- anime
|   |-- download
|   |-- downloads
|   |-- movies
|   `-- tv
`-- nextcloud
```

## Docker Infrastructure

```bash
# Install Docker
apt install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
usermod -aG docker $USER

# Configure Docker
cat << 'EOF' > /etc/docker/daemon.json
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "btrfs"
}
EOF

docker network create proxy
docker network create database

# Enable and start Docker
systemctl enable --now docker
```

## Initial Setup Instructions

### 1. Environment Setup

```bash
mkdir -p /storage/data/{portainer,adguard/{work,conf},authentik/{media,certs},ntfy/{cache,etc}}
```

### 2. Network Setup

Create required Docker networks:

```bash
docker network create proxy
docker network create database
```

## Network Topology

```mermaid
graph TD
    Internet --> Cloudflare
    Cloudflare --> Cloudflared
    Cloudflared --> Traefik

    Traefik --> Authentik
    Traefik --> Portainer
    Traefik --> AdGuard
    Traefik --> UptimeKuma
    Traefik --> NTFY



    subgraph proxy_network[Proxy Network]
        Traefik
        Authentik
        Portainer
        AdGuard
        NTFY
        Watchtower --> NTFY
        UptimeKuma
    end

    subgraph database_network[Database Network]
        Authentik --> PostgreSQL
        Authentik --> Redis
    end
```

### Network Configuration

Docker networks are segregated by purpose:

```plaintext
NETWORK ID     NAME       DRIVER    SCOPE
37f70a4f30e9   bridge     bridge    local
cee66a3b8a01   database   bridge    local
dd88aa295275   host       host      local
22df46ad34bf   none       null      local
e963823c489e   proxy      bridge    local
```

### Persistent Volumes

```plaintext
DRIVER    VOLUME NAME
local     portainer_data
```

## Detailed Service Documentation

### Portainer

**Purpose**: Web-based Docker container management interface

**Configuration Details**:

- Image: portainer/portainer-ce:latest
- Authentication: Integrated with Authentik
- Data Persistence: Uses named volume `portainer_data`
- Access URL: https://portainer.alimunee.com

**Network Configuration**:

- Connected to `proxy` network
- Exposed Ports:
  - 8000: Edge agent API
  - 9443: HTTPS web interface

**Dependencies**:

- Requires Docker socket access
- Depends on Traefik for routing
- Optional integration with Authentik for SSO

**Deployment Configuration**

```yaml
# /storage/data/portainer/docker-compose.yml
version: '3.8'

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    networks:
      - proxy
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.portainer.rule=Host(`portainer.alimunee.com`)'
      - 'traefik.http.services.portainer.loadbalancer.server.port=9000'
      - 'traefik.docker.network=proxy'
    ports:
      - '8000:8000'
      - '9443:9443'

volumes:
  portainer_data:
    name: portainer_data
    external: true

networks:
  proxy:
    external: true
```

### Cloudflared

**Purpose**: Cloudflare Tunnel for secure remote access

**Configuration Details**:

- Image: cloudflare/cloudflared:latest
- Secure tunnel configuration
- No ports exposed to the internet

**Deployment Configuration**

```yaml
version: '3.8'

services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token eyJhIjoiNjAwMzMwNjhmMzk1YjQzNzQ3OWUzYmY4NzNlM2Q2OGUiLCJ0IjoiYmVjYzYwZmUtMTEyZS00ZDRmLWI2NjItODA1ZjE1NjY1MWNiIiwicyI6Ik5qTXlPREZtTlRJdE1EYzRNeTAwTURZekxUbGxORFF0TnpFMk1XVXhNakUwT0RCaSJ9
    networks:
      - proxy # Connect to the 'proxy' network you defined

networks:
  proxy:
    external: true
```

### Traefik

**Purpose**: Edge router and reverse proxy

**Configuration Details**:

- Image: traefik:v3.3
- Mode: Docker provider enabled
- Dashboard: Enabled and secured
- Debug Level: DEBUG for detailed logging

**Deployment Configuration**

```yaml
services:
  traefik:
    image: traefik:v3.3
    container_name: traefik
    restart: unless-stopped
    command:

      - --api.dashboard=true
      - --api.insecure=true
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --log.level=DEBUG
      - --accesslog=true
      - --providers.docker.network=proxy
    ports:
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - proxy
    labels:
      - "traefik.enable=true"

      - "traefik.http.middlewares.authentik.forwardauth.address=http://authentik-server:9000/outpost.goauthentik.io/auth/traefik"
      - "traefik.http.middlewares.authentik.forwardauth.trustforwardheader=true" # Important!
      - "traefik.http.middlewares.authentik.forwardauth.authresponseheaders=X-Authentik-Username, X-Authentik-Groups, X-Authentik-Email, X-Authentik-Name, X-Authentik-Uid"

      # - 'traefik.enable=true'
      # - 'traefik.http.routers.traefik.rule=Host(`traefik.alimunee.com`)'
      # - 'traefik.http.routers.traefik.service=api@internal'
      # - 'traefik.http.routers.traefik.entrypoints=web' # Keep 'web' for now
      # - 'traefik.http.services.traefik.loadbalancer.server.port=8080'
      # Basic Auth (REQUIRED now that api.insecure=false):
      # - "traefik.http.middlewares.traefik-auth.basicauth.users=admin:$apr1$/3h1JSbu$skK4Li9FHLvL/x8TkIwFD."
      # - "traefik.http.routers.traefik.middlewares=traefik-auth"

networks:
  proxy:
    external: true

networks:
  proxy:
    external: true
```

### Authentik

**Purpose**: Identity provider and SSO solution

**Components**:

1. **Server**:

   - Primary authentication service
   - Handles web interface and API
   - Port: 9999:9000

2. **Database (PostgreSQL)**:

   - Stores user data and configurations
   - Persistent volume for data storage

3. **Redis**:

   - Session management
   - Cache storage

4. **Worker**:
   - Background task processing
   - Email sending

**Configuration Details**:

- External Access: https://auth.alimunee.com
- Cookie Domain: alimunee.com
- TLS: Disabled internally (handled by Cloudflare)
- Bootstrap Admin: Configured via environment variables

**Dependencies**:

- PostgreSQL database
- Redis cache
- Traefik for routing

**Deployment Configuration**

```yaml
version: '3.8'

services:
  authentik-postgresql:
    image: postgres:16-alpine
    container_name: authentik-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-authentik}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?Authentik database password required}
      POSTGRES_DB: ${POSTGRES_DB:-authentik}
    volumes:
      - authentik-db:/var/lib/postgresql/data
    networks:
      - proxy # Connect to your shared network
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}']
      interval: 10s
      timeout: 5s
      retries: 5

  authentik-server:
    image: ghcr.io/goauthentik/server:2024.12.3
    container_name: authentik-server
    restart: unless-stopped
    command: server
    environment:
      AUTHENTIK_REDIS__HOST: authentik-redis
      AUTHENTIK_POSTGRESQL__HOST: authentik-postgresql
      AUTHENTIK_POSTGRESQL__USER: ${POSTGRES_USER:-authentik}
      AUTHENTIK_POSTGRESQL__PASSWORD: ${POSTGRES_PASSWORD:?Database password required}
      AUTHENTIK_POSTGRESQL__NAME: ${POSTGRES_DB:-authentik}
      AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY:?Authentik secret key required}
      # Authentik bootstrap (initial admin user)
      AUTHENTIK_BOOTSTRAP_EMAIL: ${AUTHENTIK_BOOTSTRAP_EMAIL:-newaaa4@gmail.com} # CHANGE THIS!
      AUTHENTIK_BOOTSTRAP_PASSWORD: ${AUTHENTIK_BOOTSTRAP_PASSWORD:?Initial admin password required}
      AUTHENTIK_BOOTSTRAP_TOKEN: ${AUTHENTIK_BOOTSTRAP_TOKEN:-} # Optional, for API access
      # Disable TLS for internal communication (Cloudflare handles TLS)
      AUTHENTIK_DISABLE_TLS: 'true'
      AUTHENTIK_OUTPOSTS__EXTERNAL_HOST: 'https://auth.alimunee.com' # Change to HTTPS since Cloudflare handles TLS
      AUTHENTIK_DEFAULT_REDIRECT: 'https://auth.alimunee.com'
      AUTHENTIK_ERROR_REPORTING__ENABLED: 'false'
      AUTHENTIK_PROXY__MODE__ENABLED: 'true'
      AUTHENTIK_COOKIE__DOMAIN: 'alimunee.com'
      AUTHENTIK_PROXY__TRUSTED_PROXIES: '0.0.0.0/0' # Trust proxies since we're behind Cloudflare

    volumes:
      - /storage/data/authentik/media:/media
      - authentik-certs:/certs
    ports:
      - '9999:9000' # Exposing this is OK because Traefik handles routing
    networks:
      - proxy
    depends_on:
      authentik-postgresql:
        condition: service_healthy
      authentik-redis:
        condition: service_healthy

    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.authentik.rule=Host(`auth.alimunee.com`)'
      - 'traefik.http.services.authentik.loadbalancer.server.port=9000'
      - 'traefik.http.middlewares.authentik-headers.headers.customRequestHeaders.X-Forwarded-Proto=https'
      - 'traefik.http.middlewares.authentik-headers.headers.customRequestHeaders.X-Forwarded-Host=auth.alimunee.com'
      - 'traefik.http.routers.authentik.middlewares=authentik-headers'
      - 'traefik.docker.network=proxy'

  authentik-worker:
    image: ghcr.io/goauthentik/server:2024.12.3
    container_name: authentik-worker
    restart: unless-stopped
    command: worker
    environment:
      AUTHENTIK_REDIS__HOST: authentik-redis
      AUTHENTIK_POSTGRESQL__HOST: authentik-postgresql
      AUTHENTIK_POSTGRESQL__USER: ${POSTGRES_USER:-authentik}
      AUTHENTIK_POSTGRESQL__PASSWORD: ${POSTGRES_PASSWORD:?Database password required}
      AUTHENTIK_POSTGRESQL__NAME: ${POSTGRES_DB:-authentik}
      AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY:?Authentik secret key required}
      # Disable TLS for internal communication (Cloudflare handles TLS)
      AUTHENTIK_DISABLE_TLS: 'true'
    volumes:
      - /storage/data/authentik/media:/media
      - authentik-certs:/certs
    networks:
      - proxy
    depends_on:
      - authentik-postgresql
      - authentik-redis

  authentik-redis:
    image: redis:alpine
    container_name: authentik-redis
    restart: unless-stopped
    networks:
      - proxy
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 10s
      timeout: 5s
      retries: 5
    volumes:
      - authentik-redis:/data

volumes:
  authentik-db:
    driver: local
  authentik-redis:
    driver: local
  authentik-certs: #  Not strictly necessary since we're using HTTP, but good practice
    driver: local

networks:
  proxy:
    external: true
```

### AdGuard

**Purpose**: DNS server and network-wide ad blocking

**Configuration Details**:

- Image: adguard/adguardhome:latest
- Data Persistence:
  - `/storage/data/adguard/work`: Working directory
  - `/storage/data/adguard/conf`: Configuration files

**Network Configuration**:

- DNS Ports: 53 (TCP/UDP)
- Web Interface: Port 8989
- Setup Interface: Port 3333
- Domain: adguard.alimunee.com

**Capabilities**:

- NET_ADMIN for DNS functionality
- Integrated with Traefik for web access

**Deployment Configuration**

```yaml
version: '3.8'

services:
  adguard:
    image: adguard/adguardhome:latest
    container_name: adguard
    restart: unless-stopped
    networks:
      - proxy
    volumes:
      - /storage/data/adguard/work:/opt/adguardhome/work
      - /storage/data/adguard/conf:/opt/adguardhome/conf
    ports:
      - '53:53/tcp' # DNS
      - '53:53/udp' # DNS
      - '8989:80'
      - '3333:3000' # initial setup then auto switch to 80
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.adguard.rule=Host(`adguard.alimunee.com`)'
      - 'traefik.http.services.adguard.loadbalancer.server.port=80'
      - 'traefik.http.middlewares.adguard-headers.headers.customRequestHeaders.X-Forwarded-Proto=https'
      - 'traefik.http.routers.adguard.middlewares=adguard-headers'
    cap_add:
      - NET_ADMIN # Required for DNS server functionality

networks:
  proxy:
    external: true
```

**AdGuard Settings**

- Use AdGuard browsing security web service
- Use AdGuard parental control web service
- Use Safe Search for all available websites except YouTube because it disables comments
- Using the following lists:

| Filter Name                                      | URL                                                                  | Entries | Updated           |
| ------------------------------------------------ | -------------------------------------------------------------------- | ------- | ----------------- |
| AdGuard DNS filter                               | https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt  | 55,465  | February 22, 2025 |
| AdAway Default Blocklist                         | https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt  | 0       | –                 |
| Phishing URL Blocklist (PhishTank and OpenPhish) | https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt | 1,500   | February 22, 2025 |
| uBlock₀ filters – Badware risks                  | https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt | 2,881   | February 22, 2025 |
| 1Hosts (Lite)                                    | https://adguardteam.github.io/HostlistsRegistry/assets/filter_24.txt | 92,033  | February 22, 2025 |
| AdGuard DNS Popup Hosts filter                   | https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt | 1,431   | February 22, 2025 |

### NTFY

**Purpose**: Self-hosted pub-sub notification service

**Configuration Details**:

- Image: binwiederhier/ntfy
- Cache Location: /var/cache/ntfy
- Configuration: /etc/ntfy
- Timezone: Asia/Kuala_Lumpur

**Security**:

- Basic authentication enabled
- Access control for topics
- Behind reverse proxy configuration

**Network Configuration**:

- Web Interface: Port 8888:80
- Domain: ntfy.alimunee.com

**Deployment Configuration**

```yaml
version: '3.8'

services:
  ntfy:
    image: binwiederhier/ntfy
    container_name: ntfy
    restart: unless-stopped
    environment:
      - TZ=Asia/Kuala_Lumpur
    volumes:
      - /storage/data/ntfy/cache:/var/cache/ntfy
      - /storage/data/ntfy/etc:/etc/ntfy
    ports:
      - '8888:80' # Local network access
    networks:
      - proxy
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.ntfy.rule=Host(`ntfy.alimunee.com`)'
      - 'traefik.http.routers.ntfy.entrypoints=web'
      - 'traefik.http.services.ntfy.loadbalancer.server.port=80'
      # Add headers for proper forwarding
      - 'traefik.http.middlewares.ntfy-headers.headers.customrequestheaders.X-Forwarded-Proto=https'
      - 'traefik.http.middlewares.ntfy-headers.headers.customrequestheaders.X-Forwarded-Host=ntfy.alimunee.com'
      # Chain the middlewares
      - 'traefik.http.routers.ntfy.middlewares=ntfy-headers@docker'
    command: serve --cache-file /var/cache/ntfy/cache.db

networks:
  proxy:
    external: true
```

```yaml
base-url: 'https://ntfy.alimunee.com'
cache-file: '/var/cache/ntfy/cache.db'
behind-proxy: true
attachment-cache-dir: '/var/cache/ntfy/attachments'

# Basic authentication for API access
auth:
  - user: 'admin'
    pass: 'CHANGE_THIS_PASSWORD' # Set a strong password
    role: 'admin'

access:
  # Allow access to all topics
  - topic: '*'
    permit: 'admin,authenticated'
    allow-access-keys: true
```

### Watchtower

**Purpose**: Automated container updates

**Configuration Details**:

- Update Interval: 86400 seconds (24 hours)
- Notifications: Integrated with NTFY
- Cleanup: Enabled for old images
- Rolling updates: Enabled

**Exclusions**:

- authentik-server
- authentik-worker
- authentik-redis
- authentik-postgresql
- traefik

**Monitoring**:

- Sends notifications via NTFY
- Custom notification templates
- Update status reporting

**Deployment Configuration**

```yaml
name: immich
services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:release
    volumes:
      - /storage/Immich/uploads:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    environment:
      - DB_DATABASE_NAME=immich
      - DB_USERNAME=postgres
      - DB_PASSWORD=immich123
      - DB_HOSTNAME=database
      - REDIS_HOSTNAME=redis
      - UPLOAD_LOCATION=/storage/Immich/uploads
      - JWT_SECRET=7f75d9074fcdbcc2a85b83160e3967de77fc6d8e2bb3edc131811033b0862c240f29936e85ffdd33a2c85b8fadb0bf23be16c6f7af371dc78a58c09a7461beb4a1bb7331c682a3da2da730b1f9b124b2a3fced0e400357c4c2772d0077ef81def374469d465c53a65edd303a2c9fb5e0ed89bccf3fc1cb924c1e19b6257034f7
      - SERVER_ENDPOINT=https://photos.alimunee.com
    depends_on:
      - redis
      - database
    restart: unless-stopped
    ports:
      - '2283:2283'
    networks:
      - proxy
      - immich_internal
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.immich.rule=Host(`photos.alimunee.com`)'
      - 'traefik.http.services.immich.loadbalancer.server.port=2283'
      - 'traefik.docker.network=proxy'
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:2283/server-info/ping']
      interval: 30s
      timeout: 10s
      retries: 3

  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:release
    volumes:
      - /storage/Immich/model-cache:/cache
    environment:
      - MACHINE_LEARNING_WORKERS=1
      - MACHINE_LEARNING_CACHE_FOLDER=/cache
    restart: unless-stopped
    networks:
      - immich_internal
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:3003']
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    container_name: redis
    image: docker.io/redis:6.2-alpine@sha256:905c4ee67b8e0aa955331960d2aa745781e6bd89afc44a8584bfd13bc890f0ae
    networks:
      - immich_internal
    healthcheck:
      test: redis-cli ping || exit 1
    restart: unless-stopped

  database:
    container_name: database
    image: docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0
    environment:
      - POSTGRES_PASSWORD=immich123
      - POSTGRES_USER=postgres
      - POSTGRES_DB=immich
      - POSTGRES_INITDB_ARGS=--data-checksums
    volumes:
      - /storage/Immich/database:/var/lib/postgresql/data
    networks:
      - immich_internal
    healthcheck:
      test: >-
        pg_isready --dbname="$${POSTGRES_DB}" --username="$${POSTGRES_USER}" || exit 1;
        Chksum="$$(psql --dbname="$${POSTGRES_DB}" --username="$${POSTGRES_USER}" --tuples-only --no-align
        --command='SELECT COALESCE(SUM(checksum_failures), 0) FROM pg_stat_database')";
        echo "checksum failure count is $$Chksum";
        [ "$$Chksum" = '0' ] || exit 1
      interval: 5m
      start_interval: 30s
      start_period: 5m
    command: >-
      postgres
      -c shared_preload_libraries=vectors.so
      -c 'search_path="$$user", public, vectors'
      -c logging_collector=on
      -c max_wal_size=2GB
      -c shared_buffers=512MB
      -c wal_compression=on
    restart: unless-stopped

networks:
  proxy:
    external: true
  immich_internal:
    name: immich_internal
```

### Uptime Kuma

**Purpose**: Self-hosted monitoring tool and status page

**Configuration Details**:

- Image: louislam/uptime-kuma:1
- Data Persistence: /storage/data/uptime-kuma:/app/data
- Security: no-new-privileges enabled
- Healthcheck configured for reliability
- Integrated with Authentik for authentication

**Network Configuration**:

- Web Interface: Port 3001
- Domain: uptime.alimunee.com
- Connected to proxy network

**Dependencies**:

- Traefik for routing
- Authentik for authentication

**Deployment Configuration**

```yaml
version: '3.8'

services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    restart: unless-stopped
    volumes:
      - /storage/data/uptime-kuma:/app/data
    security_opt:
      - no-new-privileges:true
    networks:
      - proxy
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:3001']
      interval: 60s
      timeout: 3s
      retries: 3
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.uptime.rule=Host(`uptime.alimunee.com`)'
      - 'traefik.http.services.uptime.loadbalancer.server.port=3001'
      - 'traefik.docker.network=proxy'
      # Authentik Integration
      - 'traefik.http.routers.uptime.middlewares=authentik@docker'

networks:
  proxy:
    external: true
```

### Jellyfin

**Purpose**: Self-hosted media streaming server

| Configuration Setting | Value                         |
| --------------------- | ----------------------------- |
| Image                 | `linuxserver/jellyfin:latest` |
| Hardware Acceleration | `AMD GPU enabled`             |
| Memory Limits         | `6GB max, 1GB minimum`        |
| Timezone              | `Asia/Kuala_Lumpur`           |
| PUID/PGID             | `1000`                        |

**Volume Mappings**:

| Volume        | Path                     |
| ------------- | ------------------------ |
| Configuration | `/storage/data/jellyfin` |
| Movies        | `/storage/media/movies`  |
| TV Shows      | `/storage/media/tv`      |
| Anime         | `/storage/media/anime`   |
| GPU Access    | `/dev/dri`               |

**Network Settings**:

| Setting            | Value             |
| ------------------ | ----------------- |
| Web Interface Port | `8096`            |
| Domain             | `tv.alimunee.com` |
| Network            | `proxy`           |

**Configured Libraries**:

- Movies: `/movies`
- TV Shows: `/tv`
- Anime: `/anime`

Each library is properly configured with metadata agents and scanning enabled.

**Plugin Repositories**:

| Plugin Name       | URL                                                                                      |
| ----------------- | ---------------------------------------------------------------------------------------- |
| Skip Intro        | https://manifest.intro-skipper.org/manifest.json                                         |
| SSO Plugin        | https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json |
| Ani-Sync          | https://raw.githubusercontent.com/vosmicc/jellyfin-ani-sync/master/manifest.json         |
| danieladov's Repo | https://raw.githubusercontent.com/danieladov/JellyfinPluginManifest/master/manifest.json |
| Themerr           | https://app.lizardbyte.dev/jellyfin-plugin-repo/manifest.json                            |

**Jellyfin Plugins**

The following plugins are integrated with Jellyfin to enhance its functionality:

| Plugin Name          | Description                                         |
| -------------------- | --------------------------------------------------- |
| `AniDB`              | Integrates AniDB metadata for anime content.        |
| `Anilist`            | Syncs your anime watchlist with Anilist.            |
| `AudioDB`            | Fetches metadata for music files from AudioDB.      |
| `Chapter Creator`    | Automatically creates chapters for media files.     |
| `Intro Skipper`      | Skips intros in TV shows and movies.                |
| `MusicBrainz`        | Fetches metadata for music files from MusicBrainz.  |
| `OMDb`               | Fetches metadata for movies and TV shows from OMDb. |
| `Open Subtitles`     | Downloads subtitles from Open Subtitles.            |
| `Playback Reporting` | Tracks and reports playback statistics.             |
| `Reports`            | Generates various reports for your media library.   |
| `SSO Authentication` | Integrates Single Sign-On (SSO) for authentication. |
| `Skin Manager`       | Manages and applies different skins/themes.         |
| `Studio Images`      | Fetches studio logos and images.                    |
| `Subtitle Extract`   | Extracts subtitles from media files.                |
| `TMDb`               | Fetches metadata for movies and TV shows from TMDb. |
| `Theme Songs`        | Plays theme songs for TV shows and movies.          |
| `Themerr`            | Manages and applies themes for Jellyfin.            |
| `Webhook`            | Sends webhook notifications for various events.     |

**Deployment Configuration**

```yaml
version: '3.8'

services:
  jellyfin:
    image: linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Kuala_Lumpur
      # AMD GPU support
      - AMD_VISIBLE_DEVICES=all
    volumes:
      - /storage/data/jellyfin:/config
      - /storage/media/movies:/movies
      - /storage/media/tv:/tv
      - /storage/media/anime:/anime
      # GPU device mapping
      - /dev/dri:/dev/dri
    ports:
      - 8096:8096 # For local network access
    devices:
      - /dev/dri:/dev/dri
    networks:
      - proxy
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.jellyfin.rule=Host(`tv.alimunee.com`)'
      - 'traefik.http.services.jellyfin.loadbalancer.server.port=8096'
      - 'traefik.docker.network=proxy'
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 6G
        reservations:
          memory: 1G

networks:
  proxy:
    external: true
```

### Media Management (\*arr stack)

#### Radarr

**Purpose**: Automated movie collection manager and downloader

| Configuration Setting | Value                       |
| --------------------- | --------------------------- |
| Image                 | `linuxserver/radarr:latest` |
| Data Location         | `/storage/data/radarr`      |
| Media Path            | `/storage/media/movies`     |
| Downloads Path        | `/storage/media/downloads`  |
| Port                  | `7878`                      |

#### Sonarr

**Purpose**: Automated TV show and anime collection manager

| Configuration Setting | Value                       |
| --------------------- | --------------------------- |
| Image                 | `linuxserver/sonarr:latest` |
| Data Location         | `/storage/data/sonarr`      |
| Media Paths - TV      | `/tv`                       |
| Media Paths - Anime   | `/anime`                    |
| Downloads Path        | `/downloads`                |
| Port                  | `8989`                      |

#### Prowlarr

**Purpose**: Indexer manager/proxy for \*arr stack

| Configuration Setting | Value                         |
| --------------------- | ----------------------------- |
| Image                 | `linuxserver/prowlarr:latest` |
| Data Location         | `/storage/data/prowlarr `     |
| Port                  | `9696`                        |

**Connected Services**:

| Service      | Connection          |
| ------------ | ------------------- |
| Radarr       | `radarr:7878`       |
| Sonarr       | `sonarr:8989`       |
| FlareSolverr | `flaresolverr:8191` |
| NTFY         | `http://ntfy`       |
| qBittorrent  | `qbittorrent:8080`  |

#### Bazarr

**Purpose**: Automated subtitle downloader

| Configuration Setting | Value                       |
| --------------------- | --------------------------- |
| Image                 | `linuxserver/bazarr:latest` |
| Data Location         | `/storage/data/bazarr`      |
| Media Path - Movies   | `/storage/media/movies`     |
| Media Path - TV       | `/storage/media/tv`         |
| Media Path - Anime    | `/storage/media/anime`      |
| Port                  | `6767`                      |

#### FlareSolverr

**Purpose**: Proxy service to bypass Cloudflare protection

| Configuration Setting | Value                                      |
| --------------------- | ------------------------------------------ |
| Image                 | `ghcr.io/flaresolverr/flaresolverr:latest` |
| Port                  | `8191`                                     |

#### Jellyseerr

**Purpose**: Media request and discovery platform for Jellyfin

| Configuration Setting | Value                           |
| --------------------- | ------------------------------- |
| Image                 | `fallenbagel/jellyseerr:latest` |
| Data Location         | `/storage/data/jellyseerr `     |
| Port                  | `5055`                          |

**Deployment Configuration**

```yaml
version: '3.8'

services:
  radarr:
    image: linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Kuala_Lumpur
      - AUTHENTICATION_METHOD=None
    volumes:
      - /storage/data/radarr:/config
      - /storage/media/movies:/movies
      - /storage/media/downloads:/downloads
    networks:
      - proxy
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.radarr.rule=Host(`radarr.alimunee.com`)'
      - 'traefik.http.services.radarr.loadbalancer.server.port=7878'
      - 'traefik.docker.network=proxy'

      - 'traefik.http.middlewares.radarr-headers.headers.customrequestheaders.X-Forwarded-Host=radarr.alimunee.com'
      - 'traefik.http.middlewares.radarr-headers.headers.customrequestheaders.X-Forwarded-Proto=https'
      - 'traefik.http.middlewares.radarr-headers.headers.customrequestheaders.X-Forwarded-For=0.0.0.0'
      - 'traefik.http.routers.radarr.middlewares=authentik@docker,radarr-headers'
    restart: unless-stopped

  sonarr:
    image: linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Kuala_Lumpur
      - AUTHENTICATION_METHOD=None
    volumes:
      - /storage/data/sonarr:/config
      - /storage/media/tv:/tv
      - /storage/media/anime:/anime
      - /storage/media/downloads:/downloads
    networks:
      - proxy
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.sonarr.rule=Host(`sonarr.alimunee.com`)'
      - 'traefik.http.services.sonarr.loadbalancer.server.port=8989'
      - 'traefik.docker.network=proxy'

      - 'traefik.http.middlewares.sonarr-headers.headers.customrequestheaders.X-Forwarded-Host=sonarr.alimunee.com'
      - 'traefik.http.middlewares.sonarr-headers.headers.customrequestheaders.X-Forwarded-Proto=https'
      - 'traefik.http.middlewares.sonarr-headers.headers.customrequestheaders.X-Forwarded-For=0.0.0.0'
      - 'traefik.http.routers.sonarr.middlewares=authentik@docker,sonarr-headers'
    restart: unless-stopped

  prowlarr:
    image: linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Kuala_Lumpur
    volumes:
      - /storage/data/prowlarr:/config
    networks:
      - proxy
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.prowlarr.rule=Host(`prowlarr.alimunee.com`)'
      - 'traefik.http.services.prowlarr.loadbalancer.server.port=9696'
      - 'traefik.docker.network=proxy'

      - 'traefik.http.middlewares.prowlarr-headers.headers.customrequestheaders.X-Forwarded-Host=prowlarr.alimunee.com'
      - 'traefik.http.middlewares.prowlarr-headers.headers.customrequestheaders.X-Forwarded-Proto=https'
      - 'traefik.http.middlewares.prowlarr-headers.headers.customrequestheaders.X-Forwarded-For=0.0.0.0'
      - 'traefik.http.routers.prowlarr.middlewares=authentik@docker,prowlarr-headers'
    restart: unless-stopped

  bazarr:
    image: linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Kuala_Lumpur
    volumes:
      - /storage/data/bazarr:/config
      - /storage/media/movies:/movies
      - /storage/media/tv:/tv
      - /storage/media/anime:/anime
    networks:
      - proxy
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.bazarr.rule=Host(`bazarr.alimunee.com`)'
      - 'traefik.http.services.bazarr.loadbalancer.server.port=6767'
      - 'traefik.docker.network=proxy'
      - 'traefik.http.routers.bazarr.middlewares=authentik@docker'
    restart: unless-stopped

  flaresolverr:
    image: ghcr.io/flaresolverr/flaresolverr:latest
    container_name: flaresolverr
    environment:
      - TZ=Asia/Kuala_Lumpur
    networks:
      - proxy
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.flaresolverr.rule=Host(`flaresolverr.alimunee.com`)'
      - 'traefik.http.services.flaresolverr.loadbalancer.server.port=8191'
      - 'traefik.docker.network=proxy'
    restart: unless-stopped

  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: jellyseerr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Kuala_Lumpur
    volumes:
      - /storage/data/jellyseerr:/app/config
    networks:
      - proxy
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.jellyseerr.rule=Host(`request.alimunee.com`)'
      - 'traefik.http.services.jellyseerr.loadbalancer.server.port=5055'
      - 'traefik.docker.network=proxy'
    restart: unless-stopped

networks:
  proxy:
    external: true
```

### qBittorrent

**Purpose**: BitTorrent client for downloading media

| Configuration Setting | Value                            |
| --------------------- | -------------------------------- |
| Image                 | `linuxserver/qbittorrent:latest` |
| PUID/PGID             | `1000`                           |
| Timezone              | `Asia/Kuala_Lumpur`              |
| WebUI Port            | `8088`                           |

**Volume Mappings**:

| Volume        | Path                                  |
| ------------- | ------------------------------------- |
| Configuration | `/storage/data/qbittorrent:/config`   |
| Downloads     | `/storage/media/downloads:/downloads` |

**Network Settings**:

| Setting            | Value               |
| ------------------ | ------------------- |
| Web Interface Port | `8088`              |
| BitTorrent Port    | `6881 (TCP/UDP)`    |
| Domain             | `qbit.alimunee.com` |
| Network            | `proxy`             |

**Deployment Configuration**

```yaml
version: '3.8'

services:
  qbittorrent:
    image: linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Kuala_Lumpur
      - WEBUI_PORT=8080
    volumes:
      - /storage/data/qbittorrent:/config
      - /storage/media/downloads:/downloads
    ports:
      - 8088:8080 # WebUI
      - 6881:6881
      - 6881:6881/udp
    networks:
      - proxy
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.qbittorrent.rule=Host(`qbit.alimunee.com`)'
      - 'traefik.http.services.qbittorrent.loadbalancer.server.port=8080'
      - 'traefik.docker.network=proxy'
    restart: unless-stopped

networks:
  proxy:
    external: true
```

### Immich

**Purpose**: Self-hosted photo and video management solution

**Components**:

1. **Immich Server**:

   - Primary service for the web interface and API
   - Port: 2283
   - Handles user authentication and file serving

2. **Machine Learning Service**:

   - Provides AI features like facial recognition and object detection
   - Uses a model cache for improved performance

3. **PostgreSQL Database with pgvecto-rs**:

   - Stores metadata, user information, and vector embeddings
   - Optimized for image similarity search

4. **Redis**:
   - Session management
   - Caching layer

**Configuration Details**:

- External Access: https://photos.alimunee.com
- Data Storage:
  - Uploads: `/storage/Immich/uploads`
  - Database: `/storage/Immich/database`
  - Model Cache: `/storage/Immich/model-cache`
- Authentication: Integrated with Authentik using OAuth 2.0

**OAuth Integration with Authentik**:

Immich is configured to use Authentik as an OAuth provider with the following settings:

- Client ID: `phYFthtaUQjG7DSZh8pBKW7m6dz12yu7kJFjr4wp`
- Authentication flow: Authorization Code
- Redirect URI: `https://photos.alimunee.com/auth/login`
- Scope configuration: `openid profile email`

**Network Configuration**:

- Web Interface: Port 2283
- Two networks:
  - `proxy` - For external access through Traefik
  - `immich_internal` - Private network for inter-service communication

**Deployment Configuration**

```yaml
version: '3.8'

services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:release
    volumes:
      - /storage/Immich/uploads:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    environment:
      - DB_DATABASE_NAME=immich
      - DB_USERNAME=postgres
      - DB_PASSWORD=immich123
      - DB_HOSTNAME=database
      - REDIS_HOSTNAME=redis
      - UPLOAD_LOCATION=/storage/Immich/uploads
      - JWT_SECRET=7f75d9074fcdbcc2a85b83160e3967de77fc6d8e2bb3edc131811033b0862c240f29936e85ffdd33a2c85b8fadb0bf23be16c6f7af371dc78a58c09a7461beb4a1bb7331c682a3da2da730b1f9b124b2a3fced0e400357c4c2772d0077ef81def374469d465c53a65edd303a2c9fb5e0ed89bccf3fc1cb924c1e19b6257034f7
      - SERVER_ENDPOINT=https://photos.alimunee.com
    depends_on:
      - redis
      - database
    restart: unless-stopped
    ports:
      - '2283:2283'
    networks:
      - proxy
      - immich_internal
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.immich.rule=Host(`photos.alimunee.com`)'
      - 'traefik.http.services.immich.loadbalancer.server.port=2283'
      - 'traefik.docker.network=proxy'
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:2283/server-info/ping']
      interval: 30s
      timeout: 10s
      retries: 3

  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:release
    volumes:
      - /storage/Immich/model-cache:/cache
    environment:
      - MACHINE_LEARNING_WORKERS=1
      - MACHINE_LEARNING_CACHE_FOLDER=/cache
    restart: unless-stopped
    networks:
      - immich_internal
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:3003/ping']
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    container_name: redis
    image: docker.io/redis:6.2-alpine@sha256:905c4ee67b8e0aa955331960d2aa745781e6bd89afc44a8584bfd13bc890f0ae
    networks:
      - immich_internal
    healthcheck:
      test: redis-cli ping || exit 1
    restart: unless-stopped

  database:
    container_name: database
    image: docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0
    environment:
      - POSTGRES_PASSWORD=immich123
      - POSTGRES_USER=postgres
      - POSTGRES_DB=immich
      - POSTGRES_INITDB_ARGS=--data-checksums
    volumes:
      - /storage/Immich/database:/var/lib/postgresql/data
    networks:
      - immich_internal
    healthcheck:
      test: >-
        pg_isready --dbname="$${POSTGRES_DB}" --username="$${POSTGRES_USER}" || exit 1;
        Chksum="$$(psql --dbname="$${POSTGRES_DB}" --username="$${POSTGRES_USER}" --tuples-only --no-align
        --command='SELECT COALESCE(SUM(checksum_failures), 0) FROM pg_stat_database')";
        echo "checksum failure count is $$Chksum";
        [ "$$Chksum" = '0' ] || exit 1
      interval: 5m
      start_interval: 30s
      start_period: 5m
    command: >-
      postgres
      -c shared_preload_libraries=vectors.so
      -c 'search_path="$$user", public, vectors'
      -c logging_collector=on
      -c max_wal_size=2GB
      -c shared_buffers=512MB
      -c wal_compression=on
    restart: unless-stopped

networks:
  proxy:
    external: true
  immich_internal:
    name: immich_internal
```

**Features**:

- Photo and video backup
- Facial recognition and object detection
- Timeline view
- Albums and sharing
- Mobile app support
- Metadata extraction

### Nextcloud

**Purpose**: Self-hosted cloud storage and collaboration platform

**System Architecture**:

- Docker containers orchestrated with Docker Compose
- Components: Nextcloud application, PostgreSQL database, Redis cache, Nextcloud Cron
- Authentication: Integrated with Authentik SSO via OpenID Connect
- Storage: Btrfs filesystem at `/storage/nextcloud`
- Access: Traefik reverse proxy with Cloudflare for secure remote access

**Configuration Details**:

- Image: nextcloud:latest
- Database: PostgreSQL 16-alpine
- Caching: Redis Alpine
- Background Tasks: Dedicated Nextcloud container with cron
- Domain: cloud.alimunee.com
- Data Persistence:
  - `/storage/nextcloud/data`: User files and app data
  - `/storage/nextcloud/db`: PostgreSQL database
  - `/storage/nextcloud/redis`: Redis cache
  - `/storage/nextcloud/config`: Configuration files

**Network Configuration**:

- Connected to `proxy` network for external access
- Additional `nextcloud_internal` network for container communication
- Traefik for routing and SSL termination

**Installed Applications**:

- Productivity: Calendar, Contacts, Tasks, Notes, Deck
- File Management: Text editor, PDF Viewer, Draw.io
- Integration: OpenID Connect user backend (Authentik SSO)

**Deployment Configuration**:

```yaml
version: '3.8'

services:
  nextcloud:
    image: nextcloud:latest
    container_name: nextcloud
    restart: unless-stopped
    environment:
      - POSTGRES_HOST=nextcloud-db
      - POSTGRES_DB=nextcloud
      - POSTGRES_USER=nextcloud
      - POSTGRES_PASSWORD=your_strong_db_password_here
      - REDIS_HOST=nextcloud-redis
      - REDIS_HOST_PASSWORD=your_strong_redis_password_here
      - NEXTCLOUD_ADMIN_USER=admin
      - NEXTCLOUD_ADMIN_PASSWORD=your_strong_admin_password_here
      - NEXTCLOUD_TRUSTED_DOMAINS=cloud.alimunee.com
      - PHP_MEMORY_LIMIT=2G
      - PHP_UPLOAD_LIMIT=16G
      - APACHE_DISABLE_REWRITE_IP=1
      - TRUSTED_PROXIES=172.0.0.0/8
    volumes:
      - /storage/nextcloud/data:/var/www/html/data
      - /storage/nextcloud/config:/var/www/html/config
      - /etc/localtime:/etc/localtime:ro
    networks:
      - proxy
      - nextcloud_internal
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.nextcloud.rule=Host(`cloud.alimunee.com`)'
      - 'traefik.http.services.nextcloud.loadbalancer.server.port=80'
      - 'traefik.docker.network=proxy'
      - 'traefik.http.middlewares.nextcloud-headers.headers.customrequestheaders.X-Forwarded-Proto=https'
      - 'traefik.http.middlewares.nextcloud-headers.headers.customrequestheaders.X-Forwarded-Host=cloud.alimunee.com'
      - 'traefik.http.middlewares.nextcloud-secure.headers.stsSeconds=15552000'
      - 'traefik.http.middlewares.nextcloud-secure.headers.stsIncludeSubdomains=true'
      - 'traefik.http.middlewares.nextcloud-secure.headers.stsPreload=true'
      - 'traefik.http.middlewares.nextcloud-secure.headers.contentTypeNosniff=true'
      - 'traefik.http.middlewares.nextcloud-secure.headers.browserXssFilter=true'
      - 'traefik.http.middlewares.nextcloud-secure.headers.customFrameOptionsValue=SAMEORIGIN'
      - 'traefik.http.routers.nextcloud.middlewares=nextcloud-secure,nextcloud-headers'
    depends_on:
      - nextcloud-db
      - nextcloud-redis

  nextcloud-db:
    image: postgres:16-alpine
    container_name: nextcloud-db
    restart: unless-stopped
    environment:
      - POSTGRES_DB=nextcloud
      - POSTGRES_USER=nextcloud
      - POSTGRES_PASSWORD=your_strong_db_password_here
    volumes:
      - /storage/nextcloud/db:/var/lib/postgresql/data
      - /etc/localtime:/etc/localtime:ro
    networks:
      - nextcloud_internal

  nextcloud-redis:
    image: redis:alpine
    container_name: nextcloud-redis
    restart: unless-stopped
    command: redis-server --requirepass your_strong_redis_password_here
    volumes:
      - /storage/nextcloud/redis:/data
      - /etc/localtime:/etc/localtime:ro
    networks:
      - nextcloud_internal

  nextcloud-cron:
    image: nextcloud:latest
    container_name: nextcloud-cron
    restart: unless-stopped
    volumes:
      - /storage/nextcloud/data:/var/www/html/data
      - /storage/nextcloud/config:/var/www/html/config
      - /etc/localtime:/etc/localtime:ro
    entrypoint: /cron.sh
    networks:
      - nextcloud_internal
    depends_on:
      - nextcloud
      - nextcloud-db
      - nextcloud-redis
```

**Performance Optimizations**:

- PHP parameters optimized (memory_limit, upload_max_filesize, opcache settings)
- Redis for memcache and locking
- PostgreSQL tuning
- Database maintenance via command-line tools

**Backup Procedures**:

- Automated Btrfs snapshots using Snapper
- PostgreSQL database dumps
- Configuration files backup

**Maintenance Commands**:

```bash
# Database optimization
docker exec -u www-data nextcloud php occ db:add-missing-indices
docker exec -u www-data nextcloud php occ maintenance:repair

# Storage cleanup
docker exec -u www-data nextcloud php occ trashbin:cleanup --all-users
docker exec -u www-data nextcloud php occ versions:cleanup

# System updates
docker exec -u www-data nextcloud php occ maintenance:mode --on
docker-compose pull
docker-compose up -d
docker exec -u www-data nextcloud php occ upgrade
docker exec -u www-data nextcloud php occ maintenance:mode --off
```

**Monitoring**:

- Integrated with Uptime Kuma for availability monitoring
- Notifications via NTFY
- Log monitoring for error detection

### Linkwarden

**Purpose**: Self-hosted bookmark manager and link organizer with SSO integration

**System Architecture**:

- **Components**:

  - Linkwarden application server (Node.js/Next.js)
  - PostgreSQL database for data storage
  - Authentik for Single Sign-On (SSO)

- **Configuration Details**:
  - Image: ghcr.io/linkwarden/linkwarden:latest
  - Database: PostgreSQL 16-alpine
  - Authentication: Integrated with Authentik via OAuth/OpenID Connect
  - Data Persistence:
    - `/storage/data/linkwarden/db`: PostgreSQL data
    - `/storage/data/linkwarden/data`: Bookmark data and attachments
  - External Access: https://links.alimunee.com via Cloudflare Tunnel

**Network Configuration**:

- Connected to two networks:
  - `proxy`: For external communication via Traefik
  - `internal`: For isolated database communication (named `linkwarden_internal`)
- Web Interface: Port 3000
- Traefik for routing and SSL termination

**OAuth Integration with Authentik**:

- Provider Type: OAuth2/OpenID Provider
- Client ID: CexvhAeQ6Tk7RIlzbq1oooMN9tu7VquRFkHsLIYw
- Redirect URIs:
  - `https://links.alimunee.com/api/auth/callback/authentik`
  - `https://links.alimunee.com/api/v1/auth/callback/authentik`
- Scopes: `openid`, `email`, `profile`

**Deployment Configuration**:

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    container_name: linkwarden-db
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: pass123
      POSTGRES_DB: postgres
    volumes:
      - /storage/data/linkwarden/db:/var/lib/postgresql/data
    networks:
      - internal
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 10s
      timeout: 5s
      retries: 5

  linkwarden:
    image: ghcr.io/linkwarden/linkwarden:latest
    container_name: linkwarden
    restart: always
    environment:
      - DATABASE_URL=postgresql://postgres:pass123@postgres:5432/postgres
      - NEXTAUTH_URL=https://links.alimunee.com
      - NEXTAUTH_SECRET=Z0DkpUlzSXGMGgiDT7uT9znM08Lcw/GZydXLY/2moYE=
      - NEXT_PUBLIC_AUTHENTIK_ENABLED=true
      - AUTHENTIK_CUSTOM_NAME=Authentik
      - AUTHENTIK_ISSUER=https://auth.alimunee.com/application/o/linkwarden
      - AUTHENTIK_CLIENT_ID=CexvhAeQ6Tk7RIlzbq1oooMN9tu7VquRFkHsLIYw
      - AUTHENTIK_CLIENT_SECRET=[CLIENT_SECRET]
      - NEXTAUTH_DEBUG=true
      - DISABLE_REGISTRATION=false
    volumes:
      - /storage/data/linkwarden/data:/data/data
    networks:
      - proxy
      - internal
    depends_on:
      postgres:
        condition: service_healthy
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.linkwarden.rule=Host(`links.alimunee.com`)'
      - 'traefik.http.services.linkwarden.loadbalancer.server.port=3000'
      - 'traefik.docker.network=proxy'
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '2'
        reservations:
          memory: 256M

networks:
  proxy:
    external: true
  internal:
    name: linkwarden_internal
```

**Features**:

- Bookmark management and organization
- Link categorization and tagging
- User-friendly interface
- Authentication via Authentik SSO
- Resource-efficient (256MB-1GB RAM allocation)
- Link preview generation

**Maintenance Procedures**:

- Database backup:

  ```bash
  docker exec linkwarden-db pg_dump -U postgres postgres > linkwarden_backup_$(date +%Y%m%d).sql
  ```

- Data backup:

  ```bash
  tar -czvf linkwarden_data_$(date +%Y%m%d).tar.gz /storage/data/linkwarden
  ```

- Upgrade procedure:
  ```bash
  docker-compose pull linkwarden
  docker-compose up -d linkwarden
  ```

## Maintenance Procedures

### Daily Operations

```bash
# Check logs for specific service
docker logs --since 24h [service-name]

# Check logs for all services
docker logs $(docker ps -q) --since 24h

# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"
```

### Weekly Tasks

```bash
# List all networks and their containers
docker network ls
docker network inspect proxy
docker network inspect database

# List volumes and usage
docker system df -v

# Prune unused volumes
docker volume prune --filter "label!=keep"
```

### Monthly Maintenance

```bash
# Manual update of excluded services
cd /path/to/service
docker-compose pull
docker-compose up -d

# Check for vulnerable packages
docker scan $(docker ps -q)

# Test backup restoration
cd /storage/backups
tar -tzvf docker_configs_*.tar.gz
```

### Emergency Procedures

```bash
# Quick service restart
docker-compose -f /path/to/service/docker-compose.yml restart [service-name]

# Full service rebuild
docker-compose -f /path/to/service/docker-compose.yml up -d --force-recreate
```

```bash
# Recreate networks
docker network rm proxy database
docker network create proxy
docker network create database

# Reconnect containers
docker-compose up -d
```

```bash
# Restore from backup
cd /storage/backups
tar -xzvf docker_configs_*.tar.gz -C /
docker-compose up -d
```

## Security and Auditing

### Security Best Practices

```bash
# Regular security scans
docker scan $(docker ps -q)

# Check container privileges
docker inspect --format '{{ .HostConfig.Privileged }}' $(docker ps -q)
```

### Security Auditing

```bash
# List exposed ports
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Check network isolation
for net in $(docker network ls --format "{{.Name}}"); do
  echo "Network: $net"
  docker network inspect $net --format '{{range .Containers}}{{.Name}} {{end}}'
done
```

```bash
# Check container capabilities
docker inspect --format '{{ .HostConfig.CapAdd }}' $(docker ps -q)

# List mounted volumes
docker inspect --format '{{ .Mounts }}' $(docker ps -q)
```

### Monitoring and Alerting

```bash
# Container resource usage
docker stats --no-stream

# Disk usage alerts
docker system df -v | grep "Size:"
```
