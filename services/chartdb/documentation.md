# ChartDB

## Purpose
ChartDB is a powerful, web-based database diagramming editorat instantly visualizes database schemas, enables interactive editing, and offers AI-powered SQL script exports. It supports multiple database types and provides an intuitive interface for database design and documentation.

## Configuration

| Variable            | Description                      | Default          | Required |
| ------------------- | -------------------------------- | ---------------- | -------- |
| TZ                  | Timezone setting                 | America/New_York | No       |
| OPENAI_API_KEY      | OpenAI API key for AI features   | -                | No       |
| OPENAI_API_ENDPOINT | Custom AI endpoint for local LLM | -                | No       |
| LLM_MODEL_NAME      | Custom model name for local LLM  | -                | No       |
| DISABLE_ANALYTICS   | Disable analytics tracking       | true             | No       |

### Ports
- **Internal**: 80 (HTTP)
- **External**: Accessed via Traefik reverse proxy

### Domains
- **Primary**: https://chartdb.alimunee.com

## Dependencies
- **Networks**: proxy (for Traefik routing)
- **External Services**: None (standalone application)
- **Optional**: OpenAI API for AI-powered features

## Setup

1. **Configure environment (optional)**:
   ```bash
   cd services/chartdb
   cp .env.example .env
   # Edit .env to add OpenAI API key if desired
   ```

2. **Deploy the service**:
   ```bash
   cd services/chartdb
   docker compose up -d
   ```

3. **Verify deployment**:
   ```bash
   docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"
   docker compose logs -f
   ```

4. **Test connectivity**:
   ```bash
   curl -f http://localhost/
   ```

## Usage

### Web Interface
- **URL**: https://chartdb.alimunee.com
- **Features**:
  - Visual database schema design
  - Support for multiple database types (PostgreSQL, MySQL, SQL Server, SQLite, etc.)
  - Interactive table and relationship editing
  - AI-powered SQL script generation (with API key)
  - Import existing database schemas
  - Export to various formats (SQL DDL, images)

### Key Features
- **Database Support**: PostgreSQL, MySQL, SQL Server, SQLite, MariaDB, and more
- **Visual Design**: Drag-and-drop interface for tables, columns, and relationships
- **AI Integration**: Generate SQL scripts with AI assistance (requires OpenAI API key)
- **Schema Import**: Connect to existing databases to import schemas
- **Export Options**: SQL DDL scripts, PNG images, and diagram files
- **Collaboration**: Share diagrams via URLs

### AI Features (Optional)
To enable AI-powered features:
1. Obtain an OpenAI API key
2. Add `OPENAI_API_KEY=your_key_here` to `.env` file
3. Restart the service
4. Access AI features in the interface for SQL generation and optimization

## Integration

### No Authentication Required
ChartDB runs as a client-side application with no user accounts or authentication system.

### Database Connectivity
- Can connect to live databases for schema import
- Supports read-only connections for security
- No persistent storage of database credentials

### Backup Considerations
Since ChartDB stores data client-side:
- Diagrams are saved in browser local storage
- Users should export important diagrams regularly
- No server-side backup is needed
- Consider documenting export procedures for users

## Troubleshooting

### Service Won't Start
```bash
# Check container logs
docker compose logs chartdb

# Verify image availability
docker pull ghcr.io/chartdb/chartdb:latest

# Check network connectivity
docker network ls | grep proxy
```

### 404 Errors
```bash
# Test direct container access
docker exec chartdb curl -f http://localhost:80

# Check Traefik routing
docker logs traefik | grep chartdb

# Verify health check
docker inspect chartdb | grep -A 10 Health
```

### AI Features Not Working
```bash
# Check if API key is set
docker exec chartdb env | grep OPENAI

# Verify API key validity
curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models

# Check browser console for API errors
```

### Performance Issues
```bash
# Monitor resource usage
docker stats chartdb

# Check memory limits
docker inspect chartdb | grep -A 5 Memory
```

## Backup

### No Server-Side Data
ChartDB is a client-side application that stores diagrams in browser local storage. No server-side backup is required.

### User Data Export
Recommend users to:
1. Export diagrams as SQL DDL scripts
2. Save diagram files (.chartdb format) locally
3. Export as PNG images for documentation
4. Use browser export features for local storage backup

### Configuration Backup
```bash
# Backup service configuration
cp docker-compose.yml docker-compose.yml.backup
cp .env .env.backup
cp documentation.md documentation.md.backup
```

## Monitoring

### Health Checks
- **Endpoint**: HTTP GET to root path (/)
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 3

### Resource Monitoring
- **Memory Limit**: 512MB
- **Memory Reservation**: 128MB
- **Expected Usage**: Low to moderate (web application)

### Uptime Kuma Integration
Add monitoring check:
- **Type**: HTTP
- **URL**: https://chartdb.alimunee.com
- **Interval**: 60 seconds
- **Expected Status**: 200

## Updates

ChartDB is managed by Watchtower for automatic updates:
- **Update Schedule**: Automatic when new images are available
- **Rollback**: Use `docker compose down && docker compose up -d` with previous image tag if needed
- **Monitoring**: Check Watchtower logs for update status

## Security Considerations

### API Key Security
- Store OpenAI API keys securely in `.env` file
- Never commit API keys to version control
- Monitor API usage and costs
- Consider using environment-specific API keys

### Network Security
- ChartDB runs on internal network with Traefik proxy
- No direct database write access (read-only schema import)
- Client-side data storage reduces server-side attack surface
