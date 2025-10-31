# Firefly III

**Purpose**: Personal finance managed budgeting application

**Status**: 🚧 **DEPLOYMENT READY** - Requires initial configuration

| Configuration Setting | Value                    |
| --------------------- | ------------------------ |
| Image                 | `fireflyiii/core:latest` |
| Database              | `MariaDB LTS`            |
| Cache                 | `Redis Alpine`           |
| Memory Limits         | `2GB max, 256MB minimum` |
| Timezone              | `Asia/Kuala_Lumpur`      |

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | budget.alimunee.com                         |
| Internal Port   | 8080                                        |
| TLS             | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin | Configured via web interface                |

**Volume Mappings**:

| Volume   | Path                               | Purpose                  |
| -------- | ---------------------------------- | ------------------------ |
| Upload   | `/storage/data/firefly-iii/upload` | File uploads and imports |
| Export   | `/storage/data/firefly-iii/export` | Data exports             |
| Database | `/storage/data/firefly-iii/db`     | MariaDB database files   |
| Redis    | `/storage/data/firefly-iii/redis`  | Redis cache data         |

**Network Settings**:

| Setting            | Value                                     |
| ------------------ | ----------------------------------------- |
| Web Interface Port | `8080`                                    |
| Domain             | `budget.alimunee.com`                     |
| Networks           | `proxy`, `firefly_internal`, `db_network` |

**Service Components**:

- **firefly-iii**: Main application server
- **firefly-iii-db**: MariaDB database with performance optimizations
- **firefly-iii-redis**: Redis cache for sessions and queues
- **firefly-iii-cron**: Automated maintenance tasks (daily at 3 AM)

## 🔧 Initial Setup

### **1. Environment Configuration**

Generate secure passwords and tokens:

```bash
# Generate APP_KEY (32 characters)
openssl rand -base64 32

# Generate database passwords
openssl rand -base64 32

# Generate Redis password
openssl rand -base64 32

# Generate cron token (exactly 32 characters)
openssl rand -hex 16
```

Update `.env` file with generated values:
- `APP_KEY`: Laravel application key
- `DB_PASSWORD`: Database password
- `MYSQL_ROOT_PASSWORD`: MariaDB root password
- `REDIS_PASSWORD`: Redis authentication password
- `STATIC_CRON_TOKEN`: Cron job authentication token

### **2. Storage Preparation**

```bash
# Create required directories
sudo mkdir -p /storage/data/firefly-iii/{upload,export,db,redis}
sudo chown -R 1000:1000 /storage/data/firefly-iii/
```

### **3. Network Setup**

```bash
# Ensure required networks exist
docker network create proxy 2>/dev/null || true
docker network create db_network 2>/dev/null || true
```

### **4. Deployment**

```bash
cd /HOMELAB/services/firefly-iii
docker compose up -d
```

### **5. Initial Configuration**

1. Access https://budget.alimunee.com
2. Complete the initial setup wizard:
   - Create admin account
   - Configure currency preferences
   - Set up initial accounts (checking, savings, etc.)
   - Configure budget categories

## 🔐 Security Configuration

**Traefik Security Headers**:
- HSTS enabled (15552000 seconds)
- Content-Type nosniff protection
- XSS filter enabled
- Secure cookies enforced

**Database Security**:
- Dedicated user with limited privileges
- Network isolation via internal networks
- Regular automated backups

**Application Security**:
- HTTPS-only access via Cloudflare
- Trusted proxy configuration
- Secure session handling with Redis

## 📊 Features & Capabilities

**Core Features**:
- Multi-currency support
- Account management (checking, savings, credit cards)
- Transaction categorization and tagging
- Budget tracking and reporting
- Bill management and recurring transactions
- Data import/export (CSV, OFX, QIF)
- Rule-based transaction automation

**Reporting**:
- Income vs expense reports
- Category breakdowns
- Budget performance tracking
- Net worth calculations
- Custom date range analysis

**Data Management**:
- Automated transaction categorization
- Duplicate detection
- Bulk transaction editing
- CSV import with mapping
- API access for integrations

## 🔄 Maintenance & Operations

### **Regular Maintenance**

```bash
# View service status
cd /HOMELAB/services/firefly-iii
docker compose ps

# Check logs
docker compose logs -f firefly-iii
docker compose logs -f firefly-iii-db

# Restart services
docker compose restart

# Update containers
docker compose pull
docker compose up -d
```

### **Database Maintenance**

```bash
# Database backup
docker exec firefly_iii_db mysqldump -u firefly -p firefly > firefly_backup_$(date +%Y%m%d).sql

# Database optimization
docker exec firefly_iii_db mysql -u root -p -e "OPTIMIZE TABLE firefly.*;"

# Check database health
docker exec firefly_iii_db mysql -u root -p -e "SHOW ENGINE INNODB STATUS\G"
```

### **Application Maintenance**

```bash
# Clear application cache
docker exec firefly_iii php artisan cache:clear
docker exec firefly_iii php artisan config:clear
docker exec firefly_iii php artisan route:clear

# Run database migrations (after updates)
docker exec firefly_iii php artisan migrate --seed

# Generate application key (if needed)
docker exec firefly_iii php artisan key:generate
```

### **Cron Job Verification**

```bash
# Check cron job logs
docker logs firefly_iii_cron

# Manual cron execution (for testing)
docker exec firefly_iii php artisan firefly-iii:cron
```

## 📈 Monitoring & Alerts

**Health Checks**:
- Application: HTTP endpoint monitoring
- Database: MariaDB connection health
- Redis: Cache connectivity
- Cron: Daily execution verification

**Key Metrics to Monitor**:
- Response time and availability
- Database performance and storage usage
- Redis memory usage
- Failed cron job executions

**Integration Points**:
- Uptime Kuma monitoring
- ntfy notifications for service issues
- Watchtower for automated updates

## 🔗 Integration Possibilities

**Future Enhancements**:
- **Zitadel SSO**: Single sign-on integration
- **API Integration**: Connect with banking APIs
- **Mobile Apps**: Firefly III mobile companion apps
- **Backup Automation**: S3 backup integration
- **Notification System**: Budget alerts via ntfy

## 🛠️ Troubleshooting

**Common Issues**:

1. **Application won't start**:
   ```bash
   # Check APP_KEY is set
   docker exec firefly_iii php artisan key:generate

   # Verify database connection
   docker exec firefly_iii php artisan migrate:status
   ```

2. **Database connection errors**:
   ```bash
   # Check database health
   docker exec firefly_iii_db mysql -u firefly -p -e "SELECT 1;"

   # Restart database
   docker compose restart firefly-iii-db
   ```

3. **Cron jobs not running**:
   ```bash
   # Verify cron token length (must be exactly 32 characters)
   echo $STATIC_CRON_TOKEN | wc -c

   # Test manual cron execution
   curl -X GET "https://budget.alimunee.com/api/v1/cron/$STATIC_CRON_TOKEN"
   ```

4. **File upload issues**:
   ```bash
   # Check upload directory permissions
   docker exec firefly_iii ls -la /var/www/html/storage/upload

   # Fix permissions if needed
   docker exec firefly_iii chown -R www-data:www-data /var/www/html/storage
   ```

**Performance Optimization**:
- Monitor MariaDB slow query log
- Optimize Redis memory usage
- Regular database maintenance
- Monitor application response times

---

**Access URLs**:
- **Web Interface**: https://budget.alimunee.com
- **API Documentation**: https://budget.alimunee.com/api/v1/about

**Last Updated**: October 23, 2025
**Configuration Status**: 🚧 Ready for deployment
