# Operations & Maintenance

## Overview

Day-to-day operational procedures, maintenance tasks, and emergency procedures for the Docker infrastructure.

## Deployment Procedures

### Standard Deployment Process
1. **Preparation**
   ```bash
   cd /HOMELAB/services/[service-name]
   cat docker-compose.yml
   cat .env
   ```

2. **Environment Configuration**
   ```bash
   # Generate secure passwords
   openssl rand -base64 32

   # Update .env file
   nano .env
   ```

3. **Network & Stor
   ```bash
   # Create required networks
   docker network create proxy
   docker network create db_network
   docker network create mail_network

   # Create rtorage directories
   sudo mkdir -p /storage/data/[service]/
   sudo chown -R 1000:1000 /storage/data/[service]/
   ```

4. **Service Deployment**
   ```bash
   docker compose up -d
   docker compose ps
   docker compose logs -f
   ```

5. **Verification**
   ```bash
   curl -f https://[service].alimunee.com/
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

### Database Backups
```bash
#!/bin/bash
# Automated database backup script
BACKUP_DIR="/storage/backups/databases/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# PostgreSQL services
POSTGRES_SERVICES="immich nextcloud paperless-ngx zitadel karakeep firefly-iii infisical onlyoffice n8n cloudreve affine linkwarden"

for service in $POSTGRES_SERVICES; do
    docker exec ${service}-db pg_dumpvice} ${service} > "$BACKUP_DIR/${service}-$(date +%Y%m%d).sql"
    gzip "$BACKUP_DIR/${service}-$(date +%Y%m%d).sql"
done

# MariaDB services
docker exec booklore-db mariadb-dump -u bookloreklore > "$BACKUP_DIR/booklore-$(date +%Y%m%d).sql"
gzip "$BACKUP_DIR/booklore-$(date +%Y%m%d).sql"

# MongoDB services
docker exec komodo-mongo mongodump --db komodo --out "$BACKUP_DIR/"
tar -czf "$BACKUP_DIR/komodo-$(date +%Y%m%d).tar.gz" -C "$BACKUP_DIR" komodo/
rm -rf "$BACKUP_DIR/komodo/"
```

### Configuration Backups
```bash
#!/bin/bash
BACKUP_DIR="/storage/backups/configs/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup service configurations
tar -czf "$BACKUP_DIR/service-configs-$(date +%Y%m%d).tar.gz" -C /HOMELAB services/

# Backup system configurations
tar -czf "$BACKUP_DIR/system-configs-$(date +%Y%m%d).tar.gz" -C /HOMELABigs/

# Backup application data
tar -czf "$BACKUP_DIR/app-data-$(date +%Y%m%d).tar.gz" -C /storage/data .
```

### Recovery Procedures

#### Database Recovery
```bash
SERVICE="nextcloud"  # Example service

# Stop service
docker compose -f services/$SERVICE/docker-compose.yml down

# Restore database
gunzip -c /storage/backups/databases/YYYYMMDD/${SERVICE}-YYYYMMDD.sql.gz | \
docker exec -i ${SERVICE}-db psql -U ${SERVICE} ${SERVICE}

# Start service
docker compose -f services/$SERVICE/docker-compose.yml up -d
```

#### Emergency Recovery
```bash
#!/bin/bash
# Emergency recovery script

# Stop all services
cd /HOMELAB/services
find . -name "docker-compose.yml" -execdir docker-compose down \;

# Restore from latest backup
LATEST_BACKUP=$(ls -t /storage/backups/configs/ | head -1)
tar -xzf "/storage/backups/configs/$LATEST_BACKUP/service-configs-*.tar.gz" -C /HOMELAB/
tar -xzf "/storage/backups/configs/$LATEST_BACKUP/app-data-*.tar.gz" -C /storage/data/

# Fix permissions
sudo chown -R 1000:1000 /storage/data/

# Restart core services first
docker compose -f traefik/docker-compose.yml up -d
docker compose -f zitadel/docker-compose.yml up -d
docker compose -f postfix/docker-compose.yml up -d

# Wait and restart others
sleep 30
find . -name "docker-compose.yml" -not -path "./traefik/*" -not -path "./zitadel/*" -not -path "./postfix/*" -execdir docker-compose up -d
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
for service in nextcloud immich paperless-ngx;
  docker exec ${service}-db psql -U ${service} -d ${service} -c "VACUUM ANALYZE;"
done

# Storage cleanup
docker system prune -af --volumes --filter "until=168h"
```

### Updates & Upgrades

#### Manual Service Update
```bash
SERVICE="nextcloud"

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
SERVICE="traefik"  #tical service

docker compose -f /HOMELAB/services/$SERVICE/docker-compose.yml down
docker compose -f /HOMELAB/services/$SERVICE/docker-compose.yml up -d

# Verify recovery
sleep 10
curl -f https://${SERVICE}.alimunee.com/
```

### Complete Infrastructure Recovery
```bash
#!/bin/bash
# Nuclear option: restart everything

echo "Stopping all services..."
cd /HOMELAB/services
find . -name "docker-compose.yml" -execdir docker-compose down \;

echo "Starting core services..."
docker compose -f traefik/docker-compose.yml up -d
docker compose -f zitadel/docker-compose.yml up -d
docker compose -f postfix/docker-compose.yml up -d

echo "Waiting forvices..."
sleep 60

echo "Starting all other services..."
find . -name "docker-compose.yml" -not -path "./traefik/*" -not -path "./zitadel/*" -not -path "./postfix/*" -execdir docker-compose up -d \;
```

## Operational Best Practices

### Security Operations
- **Regular Updates**: Automated container updates via Watchtower
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
