# Operations & Maintenance

## Overview

Day-to-day operational procedures, maintenance tasks, and emergency procedures for the Docker infrastructure.

## Deployment Procedures

### Standard Deployment Process
1. **Preparation**
   ```bash
   cd /HOMELAB/services/[service-name]
   cat compose.yml
   cat .env
   ```

2. **Environment Configuration**
   ```bash
   # Generate secure passwords
   openssl rand -base64 32

   # Update .env file
   nano .env
   ```

3. **Network & Storage Setup**
   ```bash
   # Create required networks
   docker network create proxy
   docker network create db_network

   # Create storage directories
   sudo mkdir -p /storage/data/[service]/
   sudo chown -R 1000:1000 /storage/data/[service]/
   ```

4. **DNS Configuration Verification**
   ```bash
   # Verify DNS configuration in compose.yml
   grep -A2 "dns:" compose.yml
   # Should show:
   #   dns:
   #     - 8.8.8.8
   #     - 1.1.1.1
   ```

5. **Service Deployment**
   ```bash
   docker compose up -d
   docker compose ps
   docker compose logs -f
   ```

6. **Verification**
   ```bash
   curl -f https://[service].alimunee.com/

   # Test DNS resolution inside container
   docker exec [service] nslookup google.com
   ```

### Environment Variables Template
```yaml
# Standard .env template
DB_HOST=postgres
DB_NAME=[service]_db
DB_USER=[service]_user
DB_PASSWORD=[generate-secure-password]

APP_KEY=[generate-app-specific-key]
APP_URL=https://[service].alimunee.com

# SMTP (if needed)
SMTP_HOST=postfix
SMTP_PORT=25
SMTP_FROM=[service]@alimunee.com

# SSO (if supported)
OAUTH_WELLKNOWN_URL=https://zitadel.alimunee.com/.well-known/openid_configuration
OAUTH_CLIENT_ID=[from-zitadel]
OAUTH_CLIENT_SECRET=[from-zitadel]
```

## Backup & Recovery

Three mechanisms cover this host, and it is worth knowing which one covers what
before adding a fourth:

- **Kopia** (`configs/scripts/kopia-backup.sh`, nightly via `kopia-backup.timer`)
  snapshots `/storage/data` and `/storage/Immich` to Backblaze B2, retaining 10
  daily / 4 weekly / 3 monthly. Anything written under `/storage/data` is
  off-site the next morning.
- **Per-service logical dumps** in `/storage/data/<service>/dumps/`. Two are
  automated today: `configs/scripts/forgejo-dump.sh` and
  `configs/scripts/tuwunel-dump.sh` (both nightly, 7 kept). They are the reference
  to copy, because a live Postgres or RocksDB directory is not a restorable
  backup on its own. Forgejo writes a plain `pg_dump`; Tuwunel asks the running
  server for a managed RocksDB backup over `SIGUSR2` (`server backup-database`),
  which stays consistent without stopping the server.
- **Snapper** btrfs snapshots in `/.snapshots/` for same-host rollback.

### Database Backups
```bash
#!/bin/bash
# Automated database backup script
# Dumps are written beside each service's own data so the nightly Kopia job
# carries them to Backblaze B2 (see forgejo-dump.sh for the fuller version).
STAMP=$(date +%Y%m%d)

# PostgreSQL services
POSTGRES_SERVICES="immich paperless-ngx zitadel karakeep infisical n8n affine linkwarden"

for service in $POSTGRES_SERVICES; do
    BACKUP_DIR="/storage/data/${service}/dumps"
    sudo mkdir -p "$BACKUP_DIR"
    docker exec ${service}-db pg_dump -U ${service} -d ${service} \
        | gzip > "$BACKUP_DIR/${service}-${STAMP}.sql.gz"
done

# MongoDB services
sudo mkdir -p /storage/data/komodo/dumps
docker exec komodo-mongo mongodump --archive --gzip > "/storage/data/komodo/dumps/komodo-${STAMP}.archive.gz"
```

### Configuration Backups

Service configuration is not in `/storage` at all: `compose.yml`, the `.env`
files and everything under `configs/` live in `/HOMELAB`, which is a git
repository — that is the versioned copy. The tarballs below are a belt-and-braces
archive, written under `/storage/data` so the Kopia job carries them off-site:

```bash
#!/bin/bash
BACKUP_DIR="/storage/data/backups/configs/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup service configurations
tar -czf "$BACKUP_DIR/service-configs-$(date +%Y%m%d).tar.gz" -C /HOMELAB services/

# Backup system configurations
tar -czf "$BACKUP_DIR/system-configs-$(date +%Y%m%d).tar.gz" -C /HOMELAB configs/

# Backup application data
tar -czf "$BACKUP_DIR/app-data-$(date +%Y%m%d).tar.gz" -C /storage/data .
```

### Recovery Procedures

#### Database Recovery
```bash
SERVICE="immich"  # Example service

# Stop service
docker compose -f services/$SERVICE/compose.yml down

# Restore database
gunzip -c /storage/data/${SERVICE}/dumps/${SERVICE}-YYYYMMDD.sql.gz | \
docker exec -i ${SERVICE}-db psql -U ${SERVICE} ${SERVICE}

# Start service
docker compose -f services/$SERVICE/compose.yml up -d
```

#### Emergency Recovery
```bash
#!/bin/bash
# Emergency recovery script

# Stop all services
cd /HOMELAB/services
find . -name "compose.yml" -execdir docker-compose down \;

# Restore the data tree from the newest Kopia snapshot. The repository URL and
# KOPIA_PASSWORD live in /etc/default/kopia-backup — the file the nightly job
# sources — and the repository is owned by root:
sudo -i
source /etc/default/kopia-backup
kopia snapshot list /storage/data          # pick the snapshot ID
kopia snapshot restore <snapshot-id> /storage/data

# Restore the configuration repo. Its off-site copy is GitHub
# (git@github.com:ali-commits/homelab.git) — a PUBLIC repository, which is why
# no secret may be committed to it: .env files are gitignored and compose files
# reference ${VAR} names only.
git clone git@github.com:ali-commits/homelab.git /HOMELAB

# Fix permissions
sudo chown -R 1000:1000 /storage/data/

# Restart core services first
docker compose -f traefik/compose.yml up -d
docker compose -f zitadel/compose.yml up -d
docker compose -f postfix/compose.yml up -d

# Wait and restart others
sleep 30
find . -name "compose.yml" -not -path "./traefik/*" -not -path "./zitadel/*" -not -path "./postfix/*" -execdir docker-compose up -d
```

## Maintenance Tasks

### Daily Tasks (Automated)
```bash
#!/bin/bash
# Daily maintenance script

# Database backups
/usr/local/bin/backup-databases.sh

# Log rotation
docker system prune -f --filter "until=24h"

# Health checks
/usr/local/bin/health-check.sh
```

### Weekly Tasks
```bash
#!/bin/bash
# Weekly maintenance script

# Full system backup
/usr/local/bin/backup-full-system.sh

# Database optimization
for service in immich paperless-ngx;
  docker exec ${service}-db psql -U ${service} -d ${service} -c "VACUUM ANALYZE;"
done

# Storage cleanup
docker system prune -af --volumes --filter "until=168h"
```

### Updates & Upgrades

#### Manual Service Update
```bash
SERVICE="immich"

# Backup before update
docker exec ${SERVICE}-db pg_dump -U ${SERVICE} ${SERVICE} > "${SERVICE}-pre-update-$(date +%Y%m%d).sql"

# Update service
cd /HOMELAB/services/$SERVICE
docker compose pull
docker compose up -d

# Verify update
curl -f https://${SERVICE}.alimunee.com/
```

## Emergency Procedures

### Service Recovery
```bash
# Emergency service restart
SERVICE="traefik"  # Critical service

docker compose -f /HOMELAB/services/$SERVICE/compose.yml down
docker compose -f /HOMELAB/services/$SERVICE/compose.yml up -d

# Verify recovery
sleep 10
curl -f https://${SERVICE}.alimunee.com/
```

### Complete Infrastructure Recovery
```bash
# Nuclear option: restart everything using start-all.sh
# Traefik, Postfix, Cloudflared, AdGuard start first automatically,
# then all other services, then Sablier-managed services are stopped for wake-on-demand.
/HOMELAB/scripts/start-all.sh

# To exclude specific services:
/HOMELAB/scripts/start-all.sh -e checkmate,sablier
```

## Operational Best Practices

### Security Operations
- **Regular Updates**: Automated container updates via Arcane
- **Backup Verification**: Regular backup integrity checks
- **Access Monitoring**: Monitor service access logs
- **Secret Rotation**: Regular rotation of API keys and passwords

### Performance Operations
- **Resource Monitoring**: Continuous monitoring of system resources
- **Capacity Planning**: Proactive storage and compute capacity planning
- **Optimization**: Regular performance tuning and optimization

### Reliability Operations
- **Health Monitoring**: Comprehensive service health monitoring
- **Alerting**: Proactive alerting for service issues
- **Documentation**: Keep operational documentation up to date
- **Testing**: Regular testing of backup and recovery procedures

---

*For troubleshooting procedures, refer to [11_troubleshooting.md](11_troubleshooting.md) and individual service documentation.*
