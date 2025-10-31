# DrawDB

## Purpose
DrawDB is a free, simple, and intuitive online database diagram editor and SQL generator. This deployment builds the application from the official GitHub repository and serves it as a static web application using Nginx, providing a clean interface for database schema design and SQL script generation.

## Configuration

| Variable | Description                | Default          | Required |
| -------- | -------------------------- | ---------------- | -------- |
| TZ       | Timezone setting           | America/New_York | No       |
| NODE_ENV | Node environment for build | production       | No       |

### Ports
- **Internal**: 80 (HTTP)
- **External**: Accessed via Traefik reverse proxy

### Domains
- **Primary**: https://drawdb.alimunee.com

## Dependencies
- **Networks**: proxy (for Traefik routing)
- **External Services**: None (standalone static web application)
- **Build Dependencies**: Node.js 18, Git (handled in Docker build)

## Setup

1. **Build and deploy the service**:
   ```bash
   cd services/drawdb
   docker compose build
   docker compose up -d
   ```

2. **Verify deployment**:
   ```bash
   docker ps | grep drawdb
   docker compose logs -f
   ```

3. **Test connectivity**:
   ```bash
   curl -f http://127.0.0.1/health  # Health check endpoint
   curl -H "Host: drawdb.alimunee.com" http://localhost/  # Test via Traefik
   ```

## Usage

### Web Interface
- **URL**: https://drawdb.alimunee.com
- **Features**:
  - Intuitive drag-and-drop database diagram editor
  - SQL script generation and export
  - Multiple database type support
  - Import/export capabilities
  - Real-time visual feedback
  - Clean, modern interface

### Key Features
- **Visual Design**: Drag-and-drop interface for database schema design
- **Database Support**: PostgreSQL, MySQL, SQLite, SQL Server, and more
- **SQL Generation**: Automatic DDL script generation from diagrams
- **Import/Export**: Support for various file formats (.drawdb, SQL, images)
- **Client-Side Storage**: Diagrams saved in browser local storage
- **No Registration**: Use immediately without creating accounts

### Supported Operations
- Create and edit database tables
- Define relationships between tables
- Set primary keys, foreign keys, and indexes
- Configure column types and constraints
- Generate SQL CREATE statements
- Export diagrams as images or SQL scripts
- Import existing database schemas

## Integration

### No Authentication Required
DrawDB runs as a client-side application with no user accounts or authentication system.

### Data Storage
- **Local Storage**: Diagrams stored in browser local storage
- **Export Options**: Save diagrams as files for backup/sharing
- **Privacy**: No server-side data storage ensures privacy

### Backup Considerations
Since DrawDB stores data client-side:
- Users should regularly export important diagrams
- Use built-in export features for backup
- Save diagrams in multiple formats (JSON, SQL, PNG)
- No server-side backup is needed

## Troubleshooting

### Service Won't Start
```bash
# Check container logs
docker compose logs drawdb

# Rebuild if needed
docker compose build --no-cache
docker compose up -d

# Check network connectivity
docker network ls | grep proxy
```

### 404 Errors
```bash
# Test direct container access (use IPv4)
docker exec drawdb wget --spider http://127.0.0.1/

# Test health endpoint
docker exec drawdb wget --spider http://127.0.0.1/health

# Check Traefik routing
docker logs traefik | grep drawdb

# Verify health check status
docker ps | grep drawdb
```

### Build Issues
```bash
# Check build logs
docker compose build

# Clean build if needed
docker system prune -f
docker compose build --no-cache

# Verify source files
docker exec drawdb ls -la /usr/share/nginx/html/
```

### Performance Issues
```bash
# Monitor resource usage
docker stats drawdb

# Check memory limits
docker inspect drawdb | grep -A 5 Memory

# Check nginx processes
docker exec drawdb ps aux
```

## Backup

### No Server-Side Data
DrawDB is a client-side application that stores diagrams in browser local storage. No server-side backup is required.

### User Data Export
Recommend users to:
1. Export important diagrams as .drawdb files
2. Save SQL scripts for database recreation
3. Export as PNG images for documentation
4. Use browser export features for local storage backup

### Configuration Backup
```bash
# Backup service configuration
cp docker-compose.yml docker-compose.yml.backup
cp Dockerfile Dockerfile.backup
cp nginx.conf nginx.conf.backup
cp documentation.md documentation.md.backup
```

## Monitoring

### Health Checks
- **Endpoint**: HTTP GET to /health (returns "healthy")
- **Method**: wget with IPv4 (127.0.0.1)
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 3

### Resource Monitoring
- **Memory Limit**: 512MB
- **Memory Reservation**: 128MB
- **Expected Usage**: Low (static web application)

### Uptime Kuma Integration
Add monitoring check:
- **Type**: HTTP
- **URL**: https://drawdb.alimunee.com
- **Interval**: 60 seconds
- **Expected Status**: 200

## Updates

### Manual Updates (Custom Build)
Since this is a custom build from source:
- **Watchtower**: Disabled (custom build)
- **Update Process**: Rebuild from latest source
- **Rollback**: Keep previous image tags for rollback

```bash
# Update to latest version
cd services/drawdb
docker compose down
docker compose build --no-cache
docker compose up -d

# Rollback if needed
docker tag drawdb-drawdb:latest drawdb-drawdb:backup
# Then rebuild from known good commit
```

## Architecture

### Build Process
1. **Base Image**: Node.js 18 Alpine for building
2. **Source**: Clone from https://github.com/drawdb-io/drawdb.git
3. **Build**: npm install && npm run build
4. **Runtime**: Nginx Alpine serving static files
5. **Health Check**: Custom /health endpoint

### File Structure
```
/usr/share/nginx/html/
├── index.html          # Main application
├── assets/             # JS/CSS bundles
├── favicon.ico         # Site icon
├── hero_ss.png         # Hero image
└── robots.txt          # SEO file
```

### Nginx Configuration
- **Gzip Compression**: Enabled for performance
- **Client-Side Routing**: SPA routing support
- **Security Headers**: XSS protection, frame options
- **Static Caching**: 1-year cache for assets
- **Health Endpoint**: Custom /health route

## Security Considerations

### Network Security
- Application accessible via Traefik proxy only
- No direct external access to container
- Client-side data storage reduces server attack surface
- No database connections or external APIs

### Data Privacy
- All diagrams stored locally in browser
- No server-side data collection
- No external API calls for basic functionality
- Privacy-focused design with local-first approach

### Container Security
- Multi-stage build reduces attack surface
- Nginx runs as non-root user
- Minimal Alpine Linux base image
- No unnecessary services or packages
