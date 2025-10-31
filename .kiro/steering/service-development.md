# Service Development Guidelines

## Research and Planning Phase

### Before Starting Any Service Configuration
1. **Use Context7 for Documentation**: Always resolve library documentation first
   ```
   - Use mcp_Context7_resolve_library_id to find the correct library
   - Use mcp_Context7_get_library_docs to get up-to-date configuration examples
   - Focus on Docker, environment variables, and integration topics
   ```

2. **Use Perplexity for Current Information**: Research recent issues and solutions
   ```
   - Search for "[service-name] docker compose setup 2025"
   - Look for common configuration problems and solutions
   - Check for recent changes in image tags or configuration formats
   ```

3. **Examine Existing Services**: Study similar services in the homelab
   ```
   - Read docker-compose.yml files from similar service categories
   - Check network patterns, volume mounting, and environment variable usage
   - Review documentation.md files for structure and content patterns
   ```

## Service Configuration Standards

### Docker Compose Structure
```yaml
# Standard service template
services:
  [service-name]:
    image: [specific-tag-not-latest]
    container_name: [service_name]
    restart: unless-stopped
    environment:
      - TZ=America/New_York
      # Service-specific variables from .env
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /storage/[service]/data:/app/data
      - /storage/[service]/config:/app/config
    networks:
      - proxy                    # For web-accessible services
      - [service]_internal       # For multi-container services
      - db_network              # If using shared database
      - mail_network            # If using SMTP relay
    labels:
      # Traefik labels for web services
      - "traefik.enable=true"
      - "traefik.http.routers.[service].rule=Host(`[service].alimunee.com`)"
      - "traefik.http.routers.[service].tls=true"
      - "traefik.http.services.[service].loadbalancer.server.port=[port]"
      # Watchtower labels
      - "com.centurylinklabs.watchtower.enable=true"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:[port]/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  proxy:
    external: true
  db_network:
    external: true
  mail_network:
    external: true
  [service]_internal:
    driver: bridge
```

### Environment File (.env) Standards
```bash
# Database Configuration (if needed)
DB_HOST=postgres
DB_NAME=[service]_db
DB_USER=[service]_user
DB_PASSWORD=[generate-secure-password]

# Application Configuration
APP_KEY=[generate-app-specific-key]
APP_URL=https://[service].alimunee.com

# SMTP Configuration (if needed)
SMTP_HOST=postfix
SMTP_PORT=25
SMTP_FROM=[service]@alimunee.com

# External Integrations
SSO_CLIENT_ID=[from-Zitadel]
SSO_CLIENT_SECRET=[from-sso-provider]
```

*For complete environment configuration examples, see [docs/docker/12_operations.md](docs/docker/12_operations.md)*

## Network Architecture Patterns

### Network Selection Guide
- **proxy**: All web-accessible services (required for Traefik routing)
- **db_network**: Services using shared PostgreSQL/Redis instances
- **mail_network**: Services that send emails via Postfix relay
- **[service]_internal**: Multi-container services (app + database + cache)

*For complete network architecture, see [docs/docker/01_docker-networks.md](docs/docker/01_docker-networks.md)*

## Debugging and Troubleshooting

### Common 404 Error Causes & Solutions

#### 1. **Health Check Failures Preventing Traefik Routing**
**Problem**: Service returns 404 even though container is running and Traefik labels are correct.
**Root Cause**: Failed health checks prevent Traefik from routing traffic to the service.

**Solution**:
```yaml
# ❌ WRONG - Non-existent health endpoint
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]

# ✅ CORRECT - Test actual working endpoint or remove health check
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/"]

# ✅ OR remove health check entirely if not needed
```

**Debug Steps**:
```bash
# 1. Test the health endpoint directly
docker exec <container> curl -f http://localhost:3000/api/health

# 2. If 404, test root endpoint
docker exec <container> curl -f http://localhost:3000/

# 3. Remove health check if endpoint doesn't exist
```

#### 2. **TLS Configuration Conflicts**
**Problem**: New services get 404 while existing services work fine.
**Root Cause**: Explicit TLS labels conflict with automatic Cloudflare tunnel SSL handling.

**Solution**:
```yaml
# ❌ WRONG - Explicit TLS causes conflicts
labels:
  - "traefik.http.routers.service.tls=true"

# ✅ CORRECT - Let Cloudflare handle TLS
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.service.rule=Host(`service.alimunee.com`)"
  - "traefik.http.services.service.loadbalancer.server.port=3000"
  - "traefik.docker.network=proxy"
```

#### 3. **Router Name Conflicts**
**Problem**: Traefik doesn't detect the service router.
**Root Cause**: Router names must be unique across all services.

**Solution**:
```yaml
# ❌ WRONG - Generic names may conflict
labels:
  - "traefik.http.routers.app.rule=Host(`service.alimunee.com`)"

# ✅ CORRECT - Use unique, descriptive names
labels:
  - "traefik.http.routers.linkwarden.rule=Host(`bookmarks.alimunee.com`)"
  # OR use domain-based naming
  - "traefik.http.routers.bookmarks.rule=Host(`bookmarks.alimunee.com`)"
```

#### 4. **Missing Dependencies**
**Problem**: Service starts but doesn't function properly, returns errors.
**Root Cause**: Missing required services (databases, search engines, etc.).

**Solution**:
```yaml
# ✅ Check official documentation for ALL required services
services:
  app:
    depends_on:
      - database
      - search-engine  # Don't forget additional services!
      - cache

  # Add ALL dependencies mentioned in official docs
  search-engine:
    image: getmeili/meilisearch:v1.12.8
```

### Initial Deployment Debugging
1. **Check Container Status**: `docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"`
2. **Network Connectivity Testing**: Test database and SMTP connections
3. **Environment Variable Verification**: Check service environment variables

*For complete debugging procedures, see [docs/docker/11_troubleshooting.md](docs/docker/11_troubleshooting.md)*

### Common Issues and Solutions

#### Database Connection Issues
- **Problem**: Service can't connect to PostgreSQL
- **Solution**: Add `db_network` to networks section

#### SMTP Configuration Issues
- **Problem**: Email notifications not working
- **Solution**: Add `mail_network` and verify SMTP environment variables

#### Traefik Routing Issues
- **Problem**: Service not accessible via subdomain
- **Solution**: Ensure service is on `proxy` network with correct labels

*For detailed troubleshooting, see [docs/docker/11_troubleshooting.md](docs/docker/11_troubleshooting.md)*

## Security Best Practices

### Password Generation
```bash
# Generate secure passwords
openssl rand -base64 32

# Generate Laravel APP_KEY
echo "base64:$(openssl rand -base64 32)"
```

### Container Security
- Use specific image tags, avoid `latest`
- Run containers as non-root when possible
- Use internal networks for service-to-service communication
- Implement proper health checks

*For complete security guidelines, see individual service documentation*

## Documentation Requirements

### Required Sections in documentation.md
1. **Purpose**: Service role and functionality
2. **Configuration**: Environment variables table with descriptions
3. **Dependencies**: Required services and networks
4. **Setup**: Step-by-step deployment instructions
5. **Usage**: Access URLs and admin interfaces
6. **Integration**: SSO setup, SMTP configuration, monitoring
7. **Troubleshooting**: Common issues and debug commands
8. **Backup**: Data backup and restore procedures

### Configuration Tables Format
```markdown
| Variable  | Description         | Default  | Required |
| --------- | ------------------- | -------- | -------- |
| DB_HOST   | Database hostname   | postgres | Yes      |
| SMTP_HOST | SMTP relay hostname | postfix  | No       |
```

## Development Standards

### Prohibited Practices
- **NEVER create deployment scripts**: Do not create deploy.sh, setup.sh, or any automated deployment scripts
- Services should be deployed using standard `docker compose up -d` commands
- All deployment instructions should be in documentation.md only

## Testing and Validation

### Pre-Deployment Checklist
- [ ] Research service with Context7 and Perplexity
- [ ] Review similar services for patterns
- [ ] Create docker-compose.yml following standards
- [ ] Generate secure passwords and keys
- [ ] Create comprehensive .env file
- [ ] Write complete documentation.md
- [ ] Test configuration with getDiagnostics

### Post-Deployment Validation
- [ ] Container starts successfully
- [ ] Health checks pass
- [ ] Web interface accessible
- [ ] Database connectivity works
- [ ] SMTP relay functional (if applicable)
- [ ] SSO integration working (if applicable)
- [ ] Monitoring alerts configured
- [ ] Backup procedures tested

## Integration Patterns

### SSO Integration
1. Create application in Zitadel
2. Configure OIDC settings in service
3. Test authentication flow

*For SSO configuration details, see [docs/docker/04_authentication.md](docs/docker/04_authentication.md)*

### SMTP Integration
1. Add service to `mail_network`
2. Configure SMTP environment variables
3. Test email delivery

*For SMTP configuration details, see [docs/docker/06_notifications-smtp.md](docs/docker/06_notifications-smtp.md)*

### Monitoring Integration
1. Add health check endpoint
2. Configure Uptime Kuma monitoring
3. Set up ntfy notifications

*For monitoring setup, see [docs/docker/10_monitoring-management.md](docs/docker/10_monitoring-management.md)*
