# Infisical

**Purpose**: Open-source secret management platform for applications and infre

**Status**: 🚧 **DEPLOYMENT READY** - Requires initial configuration

| Configuration Setting | Value                                 |
| --------------------- | ------------------------------------- |
| Image                 | `infisical/infisical:latest-postgres` |
| Database              | `PostgreSQL 14 Alpine`                |
| Cache                 | `Redis Alpine`                        |
| Memory Limits         | `2GB max, 512MB minimum`              |
| Timezone              | `Asia/Kuala_Lumpur`                   |

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | secrets.alimunee.com                        |
| Internal Port   | 8080                                        |
| TLS             | Disabled internally (handled by Cloudflare) |
| Bootstrap Admin | Configured via web interface                |

**Volume Mappings**:

| Volume   | Path                            | Purpose                   |
| -------- | ------------------------------- | ------------------------- |
| Database | `/storage/data/infisical/db`    | PostgreSQL database files |
| Redis    | `/storage/data/infisical/redis` | Redis cache data          |

**Network Settings**:

| Setting            | Value                                       |
| ------------------ | ------------------------------------------- |
| Web Interface Port | `8080`                                      |
| Domain             | `secrets.alimunee.com`                      |
| Networks           | `proxy`, `infisical_internal`, `db_network` |

**Service Components**:

- **infisical**: Main application server (Node.js backend)
- **infisical-db**: PostgreSQL database with performance optimizations
- **infisical-redis**: Redis cache for sessions and background jobs

## 🔧 Initial Setup

### **1. Storage Preparation**

```bash
# Create required directories
sudo mkdir -p /storage/data/infisical/{db,redis}
sudo chown -R 1000:1000 /storage/data/infisical/
```

### **2. Network Setup**

```bash
# Ensure required networks exist
docker network create proxy 2>/dev/null || true
docker network create db_network 2>/dev/null || true
```

### **3. Deployment**

```bash
cd /HOMELAB/services/infisical
docker compose up -d
```

### **4. Initial Configuration**

1. Access https://secrets.alimunee.com
2. Complete the initial setup wizard:
   - Create admin account
   - Set up organization
   - Configure initial project
   - Set up authentication methods

## 🔐 Security Configuration

**Traefik Security Headers**:
- HSTS enabled (15552000 seconds)
- Content-Type nosniff protection
- XSS filter enabled
- Frame options set to SAMEORIGIN
- Secure cookies enforced

**Application Security**:
- HTTPS-only access via Cloudflare
- Trusted proxy configuration
- Multiple JWT secrets for different auth flows
- Encryption key for sensitive data
- Rate limiting enabled

**Database Security**:
- Dedicated user with limited privileges
- Network isolation via internal networks
- Regular automated backups

## 📊 Features & Capabilities

**Core Features**:
- **Secret Management**: Store and manage API keys, passwords, certificates
- **Environment Management**: Organize secrets by environments (dev, staging, prod)
- **Access Control**: Role-based permissions and fine-grained access controls
- **Secret Versioning**: Track changes and rollback capabilities
- **Audit Logging**: Complete audit trail of all secret operations

**Integration Capabilities**:
- **CLI Tool**: Command-line interface for developers
- **SDKs**: Native SDKs for popular programming languages
- **API Access**: RESTful API for custom integrations
- **CI/CD Integration**: GitHub Actions, GitLab CI, Jenkins plugins
- **Infrastructure**: Kubernetes operator, Terraform provider

**Authentication Methods**:
- **Email/Password**: Standard authentication
- **SSO Integration**: SAML, OIDC support (future Zitadel integration)
- **Service Tokens**: Machine-to-machine authentication
- **Multi-Factor Authentication**: TOTP support

**Advanced Features**:
- **Secret Scanning**: Detect secrets in code repositories
- **Dynamic Secrets**: Generate temporary credentials
- **Secret Rotation**: Automated secret rotation policies
- **Compliance**: SOC 2, GDPR compliance features

## 🔄 Maintenance & Operations

### **Regular Maintenance**

```bash
# View service status
cd /HOMELAB/services/infisical
docker compose ps

# Check logs
docker compose logs -f infisical
docker compose logs -f infisical-db

# Restart services
docker compose restart

# Update containers
docker compose pull
docker compose up -d
```

### **Database Maintenance**

```bash
# Database backup
docker exec infisical_db pg_dump -U infisical infisical > infisical_backup_$(date +%Y%m%d).sql

# Database optimization
docker exec infisical_db psql -U infisical -d infisical -c "VACUUM ANALYZE;"

# Check database health
docker exec infisical_db psql -U infisical -d infisical -c "SELECT version();"
```

### **Application Maintenance**

```bash
# Check application health
curl -f https://secrets.alimunee.com/api/status

# View application metrics (if enabled)
curl -s https://secrets.alimunee.com/api/v1/admin/config

# Clear Redis cache (if needed)
docker exec infisical_redis redis-cli -a $REDIS_PASSWORD FLUSHALL
```

### **Secret Management Operations**

```bash
# Install Infisical CLI (for management)
curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash
sudo apt-get update && sudo apt-get install infisical

# Login to Infisical
infisical login --domain=https://secrets.alimunee.com

# List projects
infisical projects list

# Export secrets (for backup)
infisical secrets export --env=prod --format=json > secrets_backup.json
```

## 📈 Monitoring & Alerts

**Health Checks**:
- Application: HTTP endpoint monitoring
- Database: PostgreSQL connection health
- Redis: Cache connectivity
- API endpoints: Authentication and secret retrieval

**Key Metrics to Monitor**:
- Response time and availability
- Database performance and storage usage
- Redis memory usage
- Failed authentication attempts
- Secret access patterns

**Integration Points**:
- Uptime Kuma monitoring
- ntfy notifications for service issues
- Watchtower for automated updates
- Audit log monitoring for security events

## 🔗 Integration Possibilities

**Current Integrations**:
- **Traefik**: Reverse proxy with SSL termination
- **PostgreSQL**: Persistent data storage
- **Redis**: Session management and caching

**Future Enhancements**:
- **Zitadel SSO**: Single sign-on integration
- **Backup Automation**: S3 backup integration
- **Notification System**: Security alerts via ntfy
- **Monitoring**: Prometheus metrics export
- **CI/CD**: GitHub Actions integration for secret injection

## 🛠️ Troubleshooting

**Common Issues**:

1. **Application won't start**:
   ```bash
   # Check environment variables
   docker exec infisical env | grep -E "(ENCRYPTION_KEY|AUTH_SECRET)"

   # Verify database connection
   docker exec infisical_db psql -U infisical -d infisical -c "SELECT 1;"
   ```

2. **Database connection errors**:
   ```bash
   # Check database health
   docker exec infisical_db pg_isready -U infisical -d infisical

   # Restart database
   docker compose restart infisical-db
   ```

3. **Redis connection issues**:
   ```bash
   # Test Redis connectivity
   docker exec infisical_redis redis-cli -a $REDIS_PASSWORD ping

   # Check Redis memory usage
   docker exec infisical_redis redis-cli -a $REDIS_PASSWORD info memory
   ```

4. **Authentication problems**:
   ```bash
   # Check JWT secrets configuration
   docker logs infisical | grep -i "jwt\|auth"

   # Verify encryption key
   docker logs infisical | grep -i "encryption"
   ```

5. **Performance issues**:
   ```bash
   # Monitor database performance
   docker exec infisical_db psql -U infisical -d infisical -c "SELECT * FROM pg_stat_activity;"

   # Check Redis performance
   docker exec infisical_redis redis-cli -a $REDIS_PASSWORD info stats
   ```

**Performance Optimization**:
- Monitor PostgreSQL slow query log
- Optimize Redis memory usage
- Regular database maintenance
- Monitor application response times
- Configure appropriate resource limits

**Security Best Practices**:
- Regularly rotate JWT secrets
- Monitor audit logs for suspicious activity
- Implement proper backup encryption
- Use strong passwords for database access
- Enable rate limiting for API endpoints

## 📚 Usage Examples

**CLI Usage**:
```bash
# Set up project
infisical init

# Add secrets
infisical secrets set API_KEY "your-api-key" --env=production

# Retrieve secrets
infisical secrets get API_KEY --env=production

# Run command with secrets
infisical run --env=production -- npm start
```

**API Usage**:
```bash
# Authenticate and get token
curl -X POST https://secrets.alimunee.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'

# Get secrets
curl -X GET https://secrets.alimunee.com/api/v1/secret \
  -H "Authorization: Bearer $TOKEN"
```

---

**Access URLs**:
- **Web Interface**: https://secrets.alimunee.com
- **API Endpoint**: https://secrets.alimunee.com/api/v1
- **Documentation**: https://secrets.alimunee.com/api/docs

**Last Updated**: October 25, 2025
**Configuration Status**: 🚧 Ready for deployment
