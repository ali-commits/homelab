# Nextcloud Setup Documentation

## Overview

This document details the setup and configuration of Nextcloud in our homelab environment. The installation uses Docker containers managed through Portainer, with PostgreSQL as the database backend, Redis for caching, and integration with Authentik for Single Sign-On (SSO).

## System Architecture

- **Application Stack**: Docker containers orchestrated with Docker Compose
- **Main Components**:
  - Nextcloud (Web interface and application logic)
  - PostgreSQL (Database)
  - Redis (Caching)
  - Nextcloud Cron (Background tasks)
- **Authentication**: Authentik SSO via OpenID Connect
- **Storage**: Btrfs filesystem at `/storage/nextcloud`
- **Access**: Traefik reverse proxy with Cloudflare for secure remote access
- **Domain**: cloud.alimunee.com

## Installation Procedure

### 1. Directory Structure Setup

The following directory structure was created to store Nextcloud data:

```bash
# Main storage directories
/storage/nextcloud/        # Main Nextcloud directory
├── data/                  # User files and application data
├── db/                    # PostgreSQL database files
├── redis/                 # Redis cache data
└── config/                # Nextcloud configuration files

# Docker Compose location
/storage/data/nextcloud/   # Docker Compose configuration
```

Directory permissions were set as follows:

```bash
# Create directory structure
sudo mkdir -p /storage/nextcloud/data
sudo mkdir -p /storage/nextcloud/db
sudo mkdir -p /storage/nextcloud/redis
sudo mkdir -p /storage/nextcloud/config

# Set proper permissions
sudo chown -R 1000:1000 /storage/nextcloud/data
sudo chown -R 999:999 /storage/nextcloud/db
sudo chown -R 1000:1000 /storage/nextcloud/redis
sudo chown -R 1000:1000 /storage/nextcloud/config
```

### 2. Docker Compose Configuration

Created a docker-compose.yml file at `/storage/data/nextcloud/docker-compose.yml` with the following configuration:

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
      - "traefik.enable=true"
      - "traefik.http.routers.nextcloud.rule=Host(`cloud.alimunee.com`)"
      - "traefik.http.services.nextcloud.loadbalancer.server.port=80"
      - "traefik.docker.network=proxy"
      - "traefik.http.middlewares.nextcloud-headers.headers.customrequestheaders.X-Forwarded-Proto=https"
      - "traefik.http.middlewares.nextcloud-headers.headers.customrequestheaders.X-Forwarded-Host=cloud.alimunee.com"
      - "traefik.http.middlewares.nextcloud-secure.headers.stsSeconds=15552000"
      - "traefik.http.middlewares.nextcloud-secure.headers.stsIncludeSubdomains=true"
      - "traefik.http.middlewares.nextcloud-secure.headers.stsPreload=true"
      - "traefik.http.middlewares.nextcloud-secure.headers.contentTypeNosniff=true"
      - "traefik.http.middlewares.nextcloud-secure.headers.browserXssFilter=true"
      - "traefik.http.middlewares.nextcloud-secure.headers.customFrameOptionsValue=SAMEORIGIN"
      - "traefik.http.routers.nextcloud.middlewares=nextcloud-secure,nextcloud-headers"
    depends_on:
      - nextcloud-db
      - nextcloud-redis
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/status.php"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

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
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d $$POSTGRES_DB -U $$POSTGRES_USER"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

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
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

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

networks:
  proxy:
    external: true
  nextcloud_internal:
    name: nextcloud_internal
    driver: bridge
```

**Important Configuration Parameters:**
- Replaced `your_strong_db_password_here` with a strong password for the database
- Replaced `your_strong_redis_password_here` with a strong password for Redis caching
- Replaced `your_strong_admin_password_here` with a strong admin password
- Configured `admin` as the initial admin username

### 3. Deployment

The stack was deployed using Docker Compose:

```bash
cd /storage/data/nextcloud
docker-compose up -d
```

The deployment process:
1. Downloaded the necessary Docker images
2. Created the containers
3. Created the internal network
4. Started the services in dependency order
5. Applied Traefik configurations for routing

### 4. Initial Configuration

After deployment, Nextcloud was accessed through https://cloud.alimunee.com and the initial setup was completed with the admin credentials.

#### Performance Optimizations

The `config.php` file was updated with performance and security optimizations:

```php
<?php
$CONFIG = array (
  'htaccess.RewriteBase' => '/',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'apps_paths' =>
  array (
    0 =>
    array (
      'path' => '/var/www/html/apps',
      'url' => '/apps',
      'writable' => false,
    ),
    1 =>
    array (
      'path' => '/var/www/html/custom_apps',
      'url' => '/custom_apps',
      'writable' => true,
    ),
  ),
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' =>
  array (
    'host' => 'nextcloud-redis',
    'password' => 'pass123',
    'port' => 6379,
    'timeout' => 1.5,
  ),
  'trusted_proxies' =>
  array (
    0 => '172.0.0.0/8',
  ),
  'upgrade.disable-web' => true,
  'passwordsalt' => 'Muu1dxFJBNep2ZzEL2XgSvcFakEtao',
  'secret' => 'TEiFbmQ4czcc5gew0sxVwX3dsyzO4U8l9P47UONcFmstYti2',
  'trusted_domains' =>
  array (
    0 => 'localhost',
    1 => 'cloud.alimunee.com',
  ),
  'datadirectory' => '/var/www/html/data',
  'dbtype' => 'pgsql',
  'version' => '31.0.0.18',
  'overwrite.cli.url' => 'https://cloud.alimunee.com',
  'overwriteprotocol' => 'https',
  'dbname' => 'nextcloud',
  'dbhost' => 'nextcloud-db',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'dbuser' => 'oc_admin',
  'dbpassword' => 'BPc98ld6XH8pvkXgiuHX6xjET4TdfB',
  'installed' => true,
  'instanceid' => 'oce2y8ux9y5n',
  'default_phone_region' => 'MY',
  'filelocking.enabled' => true,
  'log_rotate_size' => 104857600,
  'maintenance_window_start' => 1,
  'preview_max_x' => 2048,
  'preview_max_y' => 2048,
  'preview_max_filesize_image' => 50,
  'jpeg_quality' => 60,
  'auth.bruteforce.protection.enabled' => true,
  'blacklisted_files' => array('.htaccess'),
  'check_for_working_wellknown_setup' => true,
  'check_for_working_htaccess' => true,
);
```

### 5. Installed Apps

The following apps were installed to enhance functionality:

**Productivity Apps:**
- Calendar
- Contacts
- Tasks
- Notes
- Deck

**File Management:**
- Text (text editor)
- PDF Viewer
- Draw.io

**Integration and Security:**
- OpenID Connect user backend (for Authentik SSO)


### 6. Authentik SSO Integration

Single Sign-On was configured using OpenID Connect authentication with our Authentik instance:

#### Authentik Configuration

1. Created an OAuth2/OpenID Provider in Authentik:
   - Name: Nextcloud
   - Client Type: Confidential
   - Client ID: KLYmo0uXZCYLZwOwK947EGAQ6psxPDQcbUwzHcz3
   - Redirect URIs: https://cloud.alimunee.com/apps/user_oidc/code
   - Scopes: openid, profile, email

2. Created an Application in Authentik:
   - Name: Nextcloud
   - Slug: nextcloud
   - Provider: Nextcloud OAuth provider

#### Nextcloud Configuration

1. Installed the "OpenID Connect user backend" app
2. Configured OpenID settings:
   - Identifier (Client ID): KLYmo0uXZCYLZwOwK947EGAQ6psxPDQcbUwzHcz3
   - Secret: [client secret from Authentik]
   - Discovery endpoint: https://auth.alimunee.com/.well-known/openid-configuration
   - Scopes: openid profile email
   - Allowed domains: alimunee.com
   - Enabled "use unique user ID"
   - Enabled "automatically create users"

### 7. PHP Optimization

PHP parameters were optimized for better performance:

```bash
docker exec -it nextcloud bash
apt-get update && apt-get install -y nano
nano /usr/local/etc/php/conf.d/nextcloud.ini
```

Added PHP parameters:
```ini
memory_limit = 2G
upload_max_filesize = 16G
post_max_size = 16G
max_execution_time = 3600
max_input_time = 3600
opcache.enable = 1
opcache.memory_consumption = 512
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 1
opcache.save_comments = 1
apc.enable_cli = 1
```

### 8. Database Optimization

Database optimizations were applied:

```bash
# Add missing indices
docker exec -u www-data nextcloud php occ db:add-missing-indices

# Convert filecache to bigint
docker exec -u www-data nextcloud php occ db:convert-filecache-bigint

# Set background jobs to run via cron
docker exec -u www-data nextcloud php occ background:cron
```

## Maintenance Procedures

### Regular Maintenance Tasks

#### Weekly Tasks

1. **Database Maintenance:**
   ```bash
   # Run Nextcloud maintenance tasks
   docker exec -u www-data nextcloud php occ maintenance:repair
   docker exec -u www-data nextcloud php occ maintenance:mimetype:update-js
   ```

2. **Check for Updates:**
   ```bash
   # Check for Nextcloud updates
   docker exec -u www-data nextcloud php occ update:check
   ```

#### Monthly Tasks

1. **Storage Cleanup:**
   ```bash
   # Clear trashed files older than 30 days
   docker exec -u www-data nextcloud php occ trashbin:cleanup --all-users

   # Clean up versions
   docker exec -u www-data nextcloud php occ versions:cleanup
   ```

2. **Database Optimization:**
   ```bash
   # Optimize database tables
   docker exec -u www-data nextcloud php occ db:add-missing-indices
   ```

### Backup Procedures

#### Automated Snapper Backups

The system uses Snapper for managing Btrfs snapshots. The snapshot structure for Nextcloud is:

```
/storage/nextcloud/.snapshots/
├── 1/
│   ├── info.xml
│   └── snapshot/
├── 2/
│   ├── info.xml
│   └── snapshot/
└── ...
```

Each numbered directory represents a snapshot with:
- `info.xml`: Contains metadata about the snapshot
- `snapshot/`: Contains the actual snapshot data

#### Creating Manual Snapshots

For manual snapshots before significant changes:

```bash
# Create a new snapshot with description
sudo snapper -c nextcloud create -d "Pre-upgrade backup"

# List all snapshots
sudo snapper -c nextcloud list
```

#### Additional Backup Strategies

1. **Database Backup:**
   ```bash
   # Backup PostgreSQL database
   docker exec nextcloud-db pg_dump -U nextcloud nextcloud > /storage/backup/nextcloud-db-$(date +%Y%m%d).sql
   ```

2. **Configuration Files Backup:**
   ```bash
   # Backup specific configuration files
   mkdir -p /storage/backup/nextcloud-config-$(date +%Y%m%d)
   cp /storage/nextcloud/config/config.php /storage/backup/nextcloud-config-$(date +%Y%m%d)/
   ```

### Disaster Recovery

#### Recovery Procedure Using Snapper

In case of system failure, follow these steps to restore Nextcloud:

1. **Identify the Snapshot to Restore:**
   ```bash
   # List available snapshots
   sudo snapper -c nextcloud list
   ```

2. **Restore from Snapshot:**
   ```bash
   # Put Nextcloud in maintenance mode if it's running
   docker exec -u www-data nextcloud php occ maintenance:mode --on

   # Stop Nextcloud containers
   cd /storage/data/nextcloud
   docker-compose down

   # Restore the entire subvolume to a specific snapshot (replace NUMBER with the snapshot number)
   sudo snapper -c nextcloud undochange NUMBER..0

   # Alternative method if specific files need restoration:
   # sudo cp -a /storage/nextcloud/.snapshots/NUMBER/snapshot/specific/file /storage/nextcloud/path/to/destination

   # Restore configuration files if needed from a specific backup
   # cp -r /storage/backup/nextcloud-config-[DATE]/* /storage/nextcloud/config/
   ```

3. **Restore Database:**
   ```bash
   # Start only the database container
   docker-compose up -d nextcloud-db

   # Wait for database to initialize
   sleep 30

   # Restore database
   cat /storage/backup/nextcloud-db-[DATE].sql | docker exec -i nextcloud-db psql -U nextcloud nextcloud
   ```

4. **Start Remaining Services:**
   ```bash
   # Start all services
   docker-compose up -d
   ```

5. **Verify Installation:**
   ```bash
   # Check Nextcloud status
   docker exec -u www-data nextcloud php occ maintenance:mode --off
   docker exec -u www-data nextcloud php occ status
   ```

## Monitoring and Alerting

### Uptime Monitoring

Nextcloud is monitored using Uptime Kuma:
- Monitor URL: https://cloud.alimunee.com
- Check interval: 5 minutes
- Alert on failure: Enabled
- Notification targets: ntfy.alimunee.com

### Log Monitoring

Key logs to monitor:
- Nextcloud application logs: `docker logs nextcloud`
- Database logs: `docker logs nextcloud-db`
- Redis logs: `docker logs nextcloud-redis`

## Common Operations

### User Management

1. **Adding a New User:**
   ```bash
   # Create new user via command line
   docker exec -u www-data nextcloud php occ user:add --display-name="Full Name" --group="users" username
   ```

2. **Resetting a User Password:**
   ```bash
   # Reset password for a user
   docker exec -u www-data nextcloud php occ user:resetpassword username
   ```

### Application Management

1. **Installing an App:**
   ```bash
   # Install an app via command line
   docker exec -u www-data nextcloud php occ app:install app_name
   ```

2. **Updating Apps:**
   ```bash
   # Update all apps
   docker exec -u www-data nextcloud php occ app:update --all
   ```

### System Updates

1. **Updating Nextcloud:**
   ```bash
   # Put Nextcloud in maintenance mode
   docker exec -u www-data nextcloud php occ maintenance:mode --on

   # Pull latest images
   docker-compose pull

   # Update containers
   docker-compose up -d

   # Run update script
   docker exec -u www-data nextcloud php occ upgrade

   # Turn off maintenance mode
   docker exec -u www-data nextcloud php occ maintenance:mode --off
   ```

## Troubleshooting

### Common Issues and Resolutions

1. **Database Connection Issues:**
   ```bash
   # Check database connectivity
   docker exec nextcloud-db pg_isready -d nextcloud -U nextcloud

   # Restart database if needed
   docker restart nextcloud-db
   ```

2. **Redis Connection Issues:**
   ```bash
   # Check Redis connectivity
   docker exec nextcloud-redis redis-cli -a "your_redis_password" ping

   # Restart Redis if needed
   docker restart nextcloud-redis
   ```

3. **Permission Issues:**
   ```bash
   # Fix data directory permissions
   docker exec nextcloud chown -R www-data:www-data /var/www/html/data
   ```

4. **Nextcloud Stuck in Maintenance Mode:**
   ```bash
   # Force disable maintenance mode
   docker exec -u www-data nextcloud php occ maintenance:mode --off
   ```

## Security Considerations

- **Authentik Integration:** All user authentication is managed through Authentik SSO
- **Data Encryption:** Sensitive data is encrypted at rest using Nextcloud's encryption features
- **HTTPS:** All traffic is secured via HTTPS through Traefik and Cloudflare
- **Network Isolation:** Internal services use a dedicated network `nextcloud_internal`
- **Regular Updates:** Containers are updated via Watchtower

## References

- [Nextcloud Admin Documentation](https://docs.nextcloud.com/server/latest/admin_manual/)
- [Docker Hub: Nextcloud](https://hub.docker.com/_/nextcloud)
- [Docker Hub: PostgreSQL](https://hub.docker.com/_/postgres)
- [Docker Hub: Redis](https://hub.docker.com/_/redis)
