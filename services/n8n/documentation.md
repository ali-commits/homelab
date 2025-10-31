# n8n - Workflow Automation Platform

## Purpose
n8n is a powerful workflow automation tool that allows you to connect different services and automate tasks. It provides a visual interface for creating complex workflows with triggers, actions, and data transformations.

## Configuration

### Environment Variables
| Variable                     | Description               | Default     |
| ---------------------------- | ------------------------- | ----------- |
| `POSTGRES_USER`              | PostgreSQL admin user     | `n8n_admin` |
| `POSTGRES_PASSWORD`          | PostgreSQL admin password | *Required*  |
| `POSTGRES_DB`                | PostgreSQL database name  | `n8n`       |
| `POSTGRES_NON_ROOT_USER`     | n8n application user      | `n8n_user`  |
| `POSTGRES_NON_ROOT_PASSWORD` | n8n application password  | *Required*  |

### Ports and Access
- **Internal Port**: 5678
- **External URL**: https://automate.alimunee.com
- **Database**: PostgreSQL 16 (internal network)

### Storage Volumes
- **n8n Data**: `/storage/n8n/data` → `/home/node/.n8n`
- **Database**: `/storage/n8n/db` → `/var/lib/postgresql/data`

## Dependencies
- **Networks**: `proxy`, `db_network`, `n8n_internal`
- **Database**: PostgreSQL 16-alpine
- **Reverse Proxy**: Traefik (via Cloudflare tunnel)

## Setup

### 1. Create Storage Directories
```bash
sudo mkdir -p /storage/n8n/{data,db}
sudo chown -R 1000:1000 /storage/n8n/data
sudo chown -R 999:999 /storage/n8n/db
```

### 2. Configure Environment
Edit `.env` file and set secure passwords:
```bash
cd /HOMELAB/services/n8n
# Generate secure passwords
openssl rand -base64 32  # For POSTGRES_PASSWORD
openssl rand -base64 32  # For POSTGRES_NON_ROOT_PASSWORD
```

### 3. Make Init Script Executable
```bash
chmod +x init-data.sh
```

### 4. Deploy Service
```bash
docker compose up -d
```

### 5. Verify Deployment
```bash
# Check container status
docker compose ps

# Check logs
docker compose logs -f n8n
docker compose logs -f n8n-postgres

# Test database connection
docker exec n8n-postgres pg_isready -U n8n_admin -d n8n
```

## Usage

### Initial Setup
1. Access n8n at https://automate.alimunee.com
2. Create your admin account on first visit
3. Configure your first workflow

### Key Features
- **Visual Workflow Editor**: Drag-and-drop interface for creating automations
- **400+ Integrations**: Connect to popular services (GitHub, Slack, Google, etc.)
- **Custom Code**: JavaScript and Python code nodes for complex logic
- **Webhooks**: HTTP endpoints for triggering workflows
- **Scheduling**: Cron-based workflow triggers
- **Data Processing**: Transform and manipulate data between services

### Common Use Cases
- **Home Automation**: IoT device control and monitoring
- **Media Management**: Automate media downloads and organization
- **Notifications**: Custom alert systems via ntfy, email, or messaging
- **Data Sync**: Keep services synchronized
- **Backup Automation**: Automated backup workflows
- **System Monitoring**: Custom monitoring and alerting workflows

## Integration

### Webhook Integration
- **Base URL**: `https://automate.alimunee.com/webhook/`
- **Test Webhook**: `https://automate.alimunee.com/webhook-test/`

### API Access
- **API Endpoint**: `https://automate.alimunee.com/api/v1/`
- **Authentication**: API key or session-based

## Monitoring

### Health Checks
```bash
# Application health
curl -f https://automate.alimunee.com/healthz

# Database health
docker exec n8n-postgres pg_isready -U n8n_admin -d n8n

# Container status
docker compose ps
```

### Uptime Kuma Integration
- **Monitor URL**: `https://automate.alimunee.com/healthz`
- **Check Interval**: 60 seconds
- **Timeout**: 30 seconds

### Notifications
Configure ntfy alerts for:
- Workflow failures
- Database connection issues
- High resource usage

## Troubleshooting

### Common Issues

#### Database Connection Failed
```bash
# Check database logs
docker compose logs n8n-postgres

# Verify database is ready
docker exec n8n-postgres pg_isready -U n8n_admin -d n8n

# Check network connectivity
docker exec n8n ping n8n-postgres
```

#### Workflow Execution Errors
```bash
# Check n8n logs
docker compose logs -f n8n

# Increase log verbosity (add to .env)
N8N_LOG_LEVEL=debug
```

#### Permission Issues
```bash
# Fix data directory permissions
sudo chown -R 1000:1000 /storage/n8n/data

# Fix database directory permissions
sudo chown -R 999:999 /storage/n8n/db
```

#### Memory Issues
```bash
# Monitor resource usage
docker stats n8n n8n-postgres

# Add memory limits to docker-compose.yml if needed
```

### Performance Optimization
- **Database**: Regular VACUUM and ANALYZE operations
- **Workflows**: Optimize complex workflows with fewer nodes
- **Caching**: Enable Redis caching for better performance
- **Resource Limits**: Set appropriate CPU/memory limits

## Backup

### Database Backup
```bash
# Create backup
docker exec n8n-postgres pg_dump -U n8n_admin n8n > n8n_backup_$(date +%Y%m%d).sql

# Restore backup
docker exec -i n8n-postgres psql -U n8n_admin -d n8n < n8n_backup.sql
```

### Workflow Export
```bash
# Export all workflows via API
curl -H "Authorization: Bearer YOUR_API_KEY" \
     https://automate.alimunee.com/api/v1/workflows > workflows_backup.json
```

### Complete Backup
```bash
# Backup data directory
sudo tar -czf n8n_data_backup_$(date +%Y%m%d).tar.gz -C /storage/n8n data

# Backup database
docker exec n8n-postgres pg_dump -U n8n_admin n8n | gzip > n8n_db_backup_$(date +%Y%m%d).sql.gz
```

## Security

### Best Practices
- Use strong, unique passwords for database users
- Enable 2FA for admin accounts
- Regularly update container images
- Monitor workflow execution logs
- Restrict webhook access with authentication
- Use environment variables for sensitive data
- Regular security audits of workflows

### Network Security
- Database isolated on internal network
- Web access only through Traefik/Cloudflare
- No direct database port exposure
- Webhook endpoints properly secured
