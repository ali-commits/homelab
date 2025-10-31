# Checkmate - Uptime & Infrastructure Monitoring

**Purpose**: Open-source, self-hostd infrastructure monitoring tool for tracking server hardware, response times, and incidents with real-time visualizations and alerts.

## Service Information

- **Container Image**: `bluewavelabs/checkmate:latest`
- **External URL**: https://checkmate.alimunee.com
- **Internal Port**: 52345
- **Purpose**: Comprehensive uptime monitoring and incident management

## Features

- 🔍 **Real-time uptime monitoring** for websites, APIs, and services
- 📊 **Infrastructure monitoring** with detailed hardware metrics
- 🚨 **Incident management** with automated alerting and escalation
- 📈 **Performance analytics** with response time tracking and trends
- 🎯 **Multi-protocol support** (HTTP/HTTPS, TCP, ICMP, DNS)
- 📱 **Status pages** for public incident communication
- 🔔 **Multi-channel notifications** (email, Slack, webhooks)
- 📋 **Detailed reporting** with uptime statistics and SLA tracking

## Configuration

### Environment Variables

| Variable    | Description               | Default                | Required |
| ----------- | ------------------------- | ---------------------- | -------- |
| MONGODB_URI | MongoDB connection string | -                      | Yes      |
| REDIS_URL   | Redis connection string   | -                      | Yes      |
| JWT_SECRET  | JWT signing secret        | -                      | Yes      |
| SMTP_HOST   | SMTP server hostname      | postfix                | No       |
| SMTP_PORT   | SMTP server port          | 25                     | No       |
| SMTP_FROM   | From email address        | checkmate@alimunee.com | No       |
| APP_URL     | Application base URL      | -                      | Yes      |
| NODE_ENV    | Node.js environment       | production             | No       |

### Database Configuration
- **MongoDB**: Primary database for monitors, incidents, and user data
- **Redis**: Caching and session storage for improved performance

### Volume Mounts
- `/storage/data/checkmate/server:/app/data` - Application data and logs
- `/storage/data/checkmate/mongodb:/data/db` - MongoDB data persistence
- `/storage/data/checkmate/redis:/data` - Redis data persistence

### Network Configuration
- **Internal Port**: 52345
- **External Domain**: checkmate.alimunee.com
- **Networks**: proxy, checkmate_internal, db_network, mail_network

## Dependencies

- **MongoDB 7**: Document database for application data
- **Redis 7**: In-memory cache for sessions and temporary data
- **Traefik**: Reverse proxy for SSL termination and routing
- **Postfix**: SMTP relay for email notifications
- **Storage**: `/storage/data/checkmate` for persistent data

## Setup Instructions

### 1. Generate Secure Passwords
```bash
# Generate secure passwords for services
MONGODB_ROOT_PASSWORD=$(openssl rand -base64 32)
MONGODB_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)

echo "MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD"
echo "MONGODB_PASSWORD=$MONGODB_PASSWORD"
echo "REDIS_PASSWORD=$REDIS_PASSWORD"
echo "JWT_SECRET=$JWT_SECRET"
```

### 2. Update Environment File
```bash
# Edit .env file with generated passwords
nano /HOMELAB/services/checkmate/.env
```

### 3. Create Required Directories
```bash
# Create data directories
sudo mkdir -p /storage/data/checkmate/{server,mongodb,redis}
sudo chown -R ali:ali /storage/data/checkmate
```

### 4. Deploy Service Stack
```bash
cd /HOMELAB/services/checkmate
docker compose up -d
```

### 5. Verify Deployment
```bash
# Check all containers are running
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"

# Check logs for any errors
docker logs checkmate_server
docker logs checkmate_mongodb
docker logs checkmate_redis

# Test health endpoints
curl -f http://localhost:52345/api/health
```

### 6. Initial Setup
- Navigate to: https://checkmate.alimunee.com
- Complete the initial setup wizard
- Create admin account
- Configure first monitoring targets

## Usage

### Monitor Configuration

#### Website/API Monitoring
- **HTTP/HTTPS checks**: Monitor website availability and response times
- **SSL certificate monitoring**: Track certificate expiration dates
- **Content verification**: Ensure specific content is present on pages
- **Response time thresholds**: Set alerts for slow response times

#### Infrastructure Monitoring
- **Server health checks**: Monitor CPU, memory, disk usage
- **Network connectivity**: TCP port monitoring and ping tests
- **DNS resolution**: Verify DNS records and resolution times
- **Database connectivity**: Monitor database server availability

#### Advanced Monitoring
- **Multi-step transactions**: Test complex user workflows
- **API endpoint testing**: Validate API responses and data integrity
- **Scheduled maintenance**: Configure maintenance windows
- **Geographic monitoring**: Test from multiple locations

### Incident Management

#### Automatic Incident Creation
- **Threshold-based alerts**: Create incidents when monitors fail
- **Escalation policies**: Automatic escalation after specified timeouts
- **Incident grouping**: Combine related failures into single incidents
- **Root cause analysis**: Track incident patterns and causes

#### Manual Incident Management
- **Incident creation**: Manually create incidents for planned maintenance
- **Status updates**: Provide real-time updates to stakeholders
- **Post-mortem reports**: Document lessons learned and improvements
- **Communication templates**: Standardized incident communications

### Notification Channels

#### Email Notifications
- **SMTP integration**: Uses Postfix relay for email delivery
- **Customizable templates**: Branded email notifications
- **Escalation chains**: Multiple notification levels
- **Digest reports**: Daily/weekly summary emails

#### Integration Options
- **Webhook notifications**: Custom HTTP callbacks for incidents
- **Slack integration**: Real-time alerts in Slack channels
- **PagerDuty integration**: Enterprise incident management
- **Custom integrations**: API-based notification systems

## Integration

### Monitoring Integration
- **Uptime Kuma**: Monitor Checkmate itself for meta-monitoring
- **ntfy notifications**: Additional notification channel for critical alerts
- **Grafana dashboards**: Visualize monitoring data and trends

### Security Integration
- **Zitadel SSO**: Enterprise authentication (can be configured)
- **Traefik**: SSL termination and secure routing
- **Network isolation**: Internal networks for database communication

### Backup Integration
- **MongoDB backups**: Regular database backups to S3 or local storage
- **Configuration backups**: Export monitor configurations
- **Incident history**: Preserve historical incident data

## Troubleshooting

### Common Issues

1. **Database connection errors**:
   ```bash
   # Check MongoDB status
   docker logs checkmate_mongodb

   # Test MongoDB connectivity
   docker exec checkmate_mongodb mongosh --eval "db.adminCommand('ping')"

   # Verify user creation
   docker exec checkmate_mongodb mongosh checkmate --eval "db.getUsers()"
   ```

2. **Redis connection issues**:
   ```bash
   # Check Redis status
   docker logs checkmate_redis

   # Test Redis connectivity
   docker exec checkmate_redis redis-cli ping

   # Check Redis authentication
   docker exec checkmate_redis redis-cli -a $REDIS_PASSWORD ping
   ```

3. **Email notifications not working**:
   ```bash
   # Check Postfix connectivity
   docker exec checkmate_server nc -zv postfix 25

   # Test SMTP configuration
   docker logs checkmate_server | grep -i smtp
   ```

4. **Application startup issues**:
   ```bash
   # Check application logs
   docker logs -f checkmate_server

   # Verify environment variables
   docker exec checkmate_server env | grep -E "(MONGODB|REDIS|JWT)"
   ```

### Health Check Commands
```bash
# Check all service health
docker compose ps

# Test application health endpoint
curl -f https://checkmate.alimunee.com/api/health

# Monitor resource usage
docker stats checkmate_server checkmate_mongodb checkmate_redis
```

### Database Maintenance
```bash
# MongoDB backup
docker exec checkmate_mongodb mongodump --db checkmate --out /data/db/backup

# Redis backup
docker exec checkmate_redis redis-cli --rdb /data/dump.rdb

# Check database sizes
docker exec checkmate_mongodb du -sh /data/db
docker exec checkmate_redis du -sh /data
```

## Security Considerations

- **Database security**: MongoDB and Redis run with authentication enabled
- **Network isolation**: Databases accessible only via internal networks
- **JWT security**: Strong JWT secret for session management
- **HTTPS enforcement**: All external communication over HTTPS
- **No new privileges**: Security options prevent privilege escalation
- **Custom CA support**: Can be configured for internal HTTPS endpoints

## Backup Procedures

### Automated Backups
```bash
#!/bin/bash
# Checkmate backup script

BACKUP_DIR="/backup/checkmate-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup MongoDB
docker exec checkmate_mongodb mongodump --db checkmate --out /tmp/backup
docker cp checkmate_mongodb:/tmp/backup "$BACKUP_DIR/mongodb"

# Backup Redis
docker exec checkmate_redis redis-cli --rdb /tmp/dump.rdb
docker cp checkmate_redis:/tmp/dump.rdb "$BACKUP_DIR/redis/"

# Backup configuration
cp -r /HOMELAB/services/checkmate "$BACKUP_DIR/config"
cp -r /storage/data/checkmate/server "$BACKUP_DIR/data"

echo "Backup completed: $BACKUP_DIR"
```

### Restore Procedures
```bash
# Stop services
cd /HOMELAB/services/checkmate
docker compose down

# Restore data
sudo cp -r /backup/checkmate-YYYYMMDD/data/* /storage/data/checkmate/server/
sudo cp -r /backup/checkmate-YYYYMMDD/mongodb/* /storage/data/checkmate/mongodb/
sudo cp -r /backup/checkmate-YYYYMMDD/redis/* /storage/data/checkmate/redis/

# Fix permissions
sudo chown -R ali:ali /storage/data/checkmate

# Restart services
docker compose up -d
```

## Performance Optimization

### Resource Limits
```yaml
services:
  checkmate-server:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 512M
          cpus: '0.5'

  mongodb:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
        reservations:
          memory: 1G
          cpus: '0.5'
```

### Database Optimization
- **MongoDB indexing**: Create indexes for frequently queried fields
- **Redis memory management**: Configure appropriate memory limits
- **Connection pooling**: Optimize database connection settings
- **Query optimization**: Monitor and optimize slow queries

## Useful Commands

```bash
# View application logs
docker logs -f checkmate_server

# Access MongoDB shell
docker exec -it checkmate_mongodb mongosh checkmate

# Access Redis CLI
docker exec -it checkmate_redis redis-cli

# Check monitor status via API
curl -s https://checkmate.alimunee.com/api/monitors | jq

# Restart entire stack
cd /HOMELAB/services/checkmate
docker compose restart

# Update to latest version
docker compose pull && docker compose up -d
```

## Links

- **GitHub**: https://github.com/bluewave-labs/checkmate
- **Documentation**: https://github.com/bluewave-labs/checkmate/blob/develop/README.md
- **Docker Hub**: https://hub.docker.com/r/bluewavelabs/checkmate
