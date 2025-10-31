# OnlyOffice Document Server

**Purpose**: Self-hosted officer document editing and collaboration

**System Architecture**:

- Docker containers orchestrated with Docker Compose
- Components: OnlyOffice Document Server, PostgreSQL database, Redis cache, RabbitMQ message broker
- Authentication: JWT-based security with integration capabilities for external systems

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | office.alimunee.com                   |
| Cookie Domain     | Not explicitly configured             |
| TLS               | Disabled internally (handled by Cloudflare) |
| JWT Authentication| Enabled with custom secret            |

**Data Persistence**:

- `/storage/data/onlyoffice/data`: Document server data and configurations
- `/storage/data/onlyoffice/logs`: Application logs
- `/storage/data/onlyoffice/cache`: Document cache and temporary files
- `/storage/data/onlyoffice/forgotten`: Forgotten files cleanup
- `/storage/data/onlyoffice/db`: PostgreSQL database
- `/storage/data/onlyoffice/redis`: Redis cache data
- `/storage/data/onlyoffice/rabbitmq`: RabbitMQ message queue data

**Network Configuration**:

- Connected to `proxy` network for external access
- Additional `onlyoffice_internal` network for container communication
- Connected to `db_network` for shared database access
- Traefik for routing and SSL termination

**Components**:

1. **OnlyOffice Document Server**:
   - Primary service for document editing
   - Port: 80 (internal), exposed via Traefik
   - Handles document conversion and collaborative editing

2. **PostgreSQL Database**:
   - Stores document metadata and user sessions
   - Optimized configuration for document server workloads

3. **Redis Cache**:
   - Session management and caching
   - Improves performance for concurrent users

4. **RabbitMQ Message Broker**:
   - Handles asynchronous document processing
   - Manages conversion queues and notifications

**Features**:

- Document editing (Word, Excel, PowerPoint formats)
- Real-time collaboration
- Document conversion between formats
- Integration with external storage systems
- Mobile-responsive interface
- Version history and document recovery

**Integration with Nextcloud**:

OnlyOffice can be integrated with Nextcloud for seamless document editing:

1. **Install OnlyOffice Connector in Nextcloud**:
   ```bash
   docker exec -u www-data nextcloud php occ app:install onlyoffice
   ```

2. **Configure OnlyOffice Settings in Nextcloud**:
   - Navigate to Nextcloud Admin Settings → Additional Settings → OnlyOffice
   - Document Editing Service address: `https://office.alimunee.com/`
   - JWT Secret: (from OnlyOffice `.env` file)
   - Enable JWT: Yes

3. **Security Configuration**:
   - JWT Header: `Authorization`
   - JWT in Body: Disabled (as per official docs)
   - Document Server verification: Enabled
   - Allow self-signed certificates: No (using Cloudflare SSL)

**Performance Optimizations**:

- Memory limits: 4GB max, 1GB reserved
- PostgreSQL tuning for document workloads
- Redis memory management with LRU eviction
- RabbitMQ configured for document processing queues

**Backup Procedures**:

- Automated Btrfs snapshots using Snapper
- PostgreSQL database dumps
- Configuration files backup
- Document cache can be regenerated if needed

**Maintenance Commands**:

```bash
# Service management
cd /HOMELAB/services/onlyoffice
docker compose up -d          # Start service
docker compose restart        # Restart service
docker compose logs -f        # View logs

# Database maintenance
docker exec onlyoffice-db pg_dump -U onlyoffice onlyoffice > backup.sql

# Clear document cache (if needed)
docker exec onlyoffice rm -rf /var/lib/onlyoffice/documentserver/App_Data/cache/files/*

# Check service health
docker exec onlyoffice-db pg_isready -d onlyoffice -U onlyoffice
docker exec onlyoffice-redis redis-cli --pass ${REDIS_PASSWORD} ping
docker exec onlyoffice-rabbitmq rabbitmq-diagnostics ping
docker exec onlyoffice curl -s http://localhost/healthcheck

# JWT Secret management
# Get current JWT secret (if needed)
docker exec onlyoffice /var/www/onlyoffice/documentserver/npm/json -f /etc/onlyoffice/documentserver/local.json 'services.CoAuthoring.secret.session.string'

# Admin Panel management
# Start Admin Panel (for server management)
docker exec onlyoffice sudo supervisorctl start ds:adminpanel

# Enable Admin Panel autostart
docker exec onlyoffice sudo sed 's,autostart=false,autostart=true,' -i /etc/supervisor/conf.d/ds-adminpanel.conf

# Get Admin Panel bootstrap code (valid for 1 hour)
docker exec onlyoffice sudo supervisorctl tail -f ds:adminpanel

# Test Example management (for testing only - disable in production)
# Start test example
docker exec onlyoffice sudo supervisorctl start ds:example

# Enable test example autostart (NOT recommended for production)
docker exec onlyoffice sudo sed 's,autostart=false,autostart=true,' -i /etc/supervisor/conf.d/ds-example.conf
```

**Monitoring**:

- Integrated with Uptime Kuma for availability monitoring
- Health checks for all components (PostgreSQL, Redis, RabbitMQ)
- Notifications via NTFY
- Log monitoring for error detection

**Security Features**:

- JWT authentication for API access (enabled by default from v7.2+)
- Secure headers via Traefik middleware
- Network isolation with internal networks
- Regular security updates via Watchtower
- Admin Panel with bootstrap authentication
- Test example disabled by default (security best practice)

**Admin Panel Setup**:

The OnlyOffice Admin Panel provides server management and monitoring capabilities:

1. **Enable Admin Panel**:
   ```bash
   docker exec onlyoffice sudo supervisorctl start ds:adminpanel
   docker exec onlyoffice sudo sed 's,autostart=false,autostart=true,' -i /etc/supervisor/conf.d/ds-adminpanel.conf
   ```

2. **Get Bootstrap Code**:
   ```bash
   docker exec onlyoffice sudo supervisorctl tail ds:adminpanel | grep "Bootstrap code"
   ```

3. **Access Admin Panel**: https://office.alimunee.com/adminpanel/
   - Use the bootstrap code for initial setup (valid for 1 hour)
   - Configure server settings, monitoring, and user management

**Security Notes**:
- Test example is disabled by default for security
- Admin Panel should only be enabled when needed
- Bootstrap codes expire after 1 hour for security
- JWT secret is automatically generated and secured

**Access URLs**:

- **Web Interface**: https://office.alimunee.com
- **Welcome Page**: https://office.alimunee.com/welcome/
- **API Endpoint**: https://office.alimunee.com/coauthoring/CommandService.ashx
- **Health Check**: https://office.alimunee.com/healthcheck
- **Test Example**: https://office.alimunee.com/example/ (for testing only)
- **Admin Panel**: https://office.alimunee.com/adminpanel/ (server management)

**Troubleshooting**:

Common issues and solutions:

1. **Document won't open**: Check JWT configuration matches between OnlyOffice and client
2. **Slow performance**: Monitor Redis and RabbitMQ health, check memory usage
3. **Connection errors**: Verify network connectivity and Traefik routing
4. **Database issues**: Check PostgreSQL logs and connection settings

**Resource Requirements**:

- **CPU**: 2+ cores recommended for concurrent editing
- **Memory**: 4GB allocated (can handle 10-20 concurrent users)
- **Storage**: Minimal for application, cache grows with usage
- **Network**: Good bandwidth for real-time collaboration

---

**Last Updated**: December 2024
**Configuration Status**: ✅ Ready for deployment

**Integration Status**: ✅ **CONFIGURED AND WORKING**

**Testing OnlyOffice**:

You can test OnlyOffice functionality using several methods:

1. **Direct Access**: Visit https://office.alimunee.com/welcome/ to see the welcome page
2. **Health Check**: https://office.alimunee.com/healthcheck should return `true`
3. **Nextcloud Integration**: Create/edit documents directly in Nextcloud
4. **Test Example** (development only): https://office.alimunee.com/example/

**Production Recommendations**:

- Keep test example disabled in production
- Enable Admin Panel only when needed for maintenance
- Monitor JWT secret security
- Regular backups of document cache and database
- Monitor resource usage during peak document editing times
