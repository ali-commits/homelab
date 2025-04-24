# Linkwarden with Authentik Integration Documentation

## System Overview

This document details the configuration of Linkwarden bookmark manager with Authentik Single Sign-On (SSO) integration in our homelab environment.

### Components

- **Linkwarden**: Self-hosted bookmark manager and link organizer
- **Authentik**: Identity provider for SSO
- **PostgreSQL**: Database for Linkwarden
- **Traefik**: Reverse proxy handling routing and SSL termination
- **Docker**: Container platform hosting the services

### Network Architecture

- **External Access**: `https://links.alimunee.com` via Cloudflare Tunnel
- **Internal Networks**:
  - `proxy`: For external communication
  - `linkwarden_internal`: For database communication

## Configuration Details

### Docker Compose Configuration

```yaml
version: "3.8"
services:
  postgres:
    image: postgres:16-alpine
    container_name: linkwarden-db
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: pass123
      POSTGRES_DB: postgres
    volumes:
      - /storage/data/linkwarden/db:/var/lib/postgresql/data
    networks:
      - internal
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  linkwarden:
    image: ghcr.io/linkwarden/linkwarden:latest
    container_name: linkwarden
    restart: always
    environment:
      - DATABASE_URL=postgresql://postgres:pass123@postgres:5432/postgres
      - NEXTAUTH_URL=https://links.alimunee.com
      - NEXTAUTH_SECRET=Z0DkpUlzSXGMGgiDT7uT9znM08Lcw/GZydXLY/2moYE=
      - NEXT_PUBLIC_AUTHENTIK_ENABLED=true
      - AUTHENTIK_CUSTOM_NAME=Authentik
      - AUTHENTIK_ISSUER=https://auth.alimunee.com/application/o/linkwarden
      - AUTHENTIK_CLIENT_ID=CexvhAeQ6Tk7RIlzbq1oooMN9tu7VquRFkHsLIYw
      - AUTHENTIK_CLIENT_SECRET=hwCJ8ecCUbd5PRXjtrJg7SDL3ubtg2kNnjDlB4hgyPnAdx1Fh8sF5FPX5fclxaHmxxkDCsrdJ9DyMH6MMnjtBfORXKlw1NKjmzoFeE5LDShm2vxUTlTZTPrxan7gz9lX
      - NEXTAUTH_DEBUG=true
      - DISABLE_REGISTRATION=false
    volumes:
      - /storage/data/linkwarden/data:/data/data
    networks:
      - proxy
      - internal
    depends_on:
      postgres:
        condition: service_healthy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.linkwarden.rule=Host(`links.alimunee.com`)"
      - "traefik.http.services.linkwarden.loadbalancer.server.port=3000"
      - "traefik.docker.network=proxy"
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '2'
        reservations:
          memory: 256M

networks:
  proxy:
    external: true
  internal:
    name: linkwarden_internal
```

### Authentik Configuration

#### Provider Setup

1. **Provider Type**: OAuth2/OpenID Provider
2. **Name**: Provider for LinkWarden
3. **Client Type**: Confidential
4. **Client ID**: CexvhAeQ6Tk7RIlzbq1oooMN9tu7VquRFkHsLIYw
5. **Redirect URIs**:
   - `https://links.alimunee.com/api/auth/callback/authentik`
   - `https://links.alimunee.com/api/v1/auth/callback/authentik`
6. **Scopes**: `openid`, `email`, `profile`

#### OpenID Connect Configuration

The Authentik OpenID Provider exposes the following endpoints:

```json
{
  "issuer": "https://auth.alimunee.com/application/o/linkwarden/",
  "authorization_endpoint": "https://auth.alimunee.com/application/o/authorize/",
  "token_endpoint": "https://auth.alimunee.com/application/o/token/",
  "userinfo_endpoint": "https://auth.alimunee.com/application/o/userinfo/",
  "end_session_endpoint": "https://auth.alimunee.com/application/o/linkwarden/end-session/",
  "jwks_uri": "https://auth.alimunee.com/application/o/linkwarden/jwks/"
}
```

## Troubleshooting Guide

### Common Issues

#### OAuth Error: 301 Moved Permanently

**Symptom**: NextAuth logs show "expected 200 OK, got: 301 Moved Permanently"

**Cause**: OpenID discovery process is encountering redirects that NextAuth's client doesn't handle correctly.

**Solution**:
- Ensure AUTHENTIK_ISSUER does not have a trailing slash
- Ensure all OAuth endpoints are properly defined in Authentik
- Verify that the redirect URIs in Authentik match exactly with what Linkwarden expects

#### OAuth Error: Invalid URL

**Symptom**: NextAuth logs show "only valid absolute URLs can be requested"

**Cause**: Empty or invalid URL provided to the NextAuth Authentik provider.

**Solution**:
- Ensure all environment variables have valid URLs with proper protocols (https://)
- Check for typos in domain names or paths

#### 404 Errors During Login Flow

**Symptom**: User is redirected to a 404 page after authentication attempt.

**Cause**: Mismatched callback URLs or configuration issues.

**Solution**:
- Verify redirect URIs are correctly set in Authentik
- Check that application URLs match between Authentik and Linkwarden
- Ensure Traefik is correctly routing requests

### Debugging Steps

1. **Check Linkwarden Logs**:
   ```bash
   docker logs linkwarden
   ```

2. **Verify OpenID Configuration**:
   ```bash
   curl -L https://auth.alimunee.com/application/o/linkwarden/.well-known/openid-configuration
   ```

3. **Test Authentik Provider**:
   Check if the provider is accessible and responding correctly:
   ```bash
   curl -L https://auth.alimunee.com/application/o/authorize/
   ```

4. **Inspect Network Traffic**:
   Use browser developer tools to monitor the network requests during login attempts.

## Maintenance Procedures

### Backup Procedure

1. **Database Backup**:
   ```bash
   docker exec linkwarden-db pg_dump -U postgres postgres > linkwarden_backup_$(date +%Y%m%d).sql
   ```

2. **Configuration Backup**:
   ```bash
   cp /path/to/docker-compose.yml /path/to/backups/linkwarden_compose_$(date +%Y%m%d).yml
   ```

3. **Data Backup**:
   ```bash
   tar -czvf linkwarden_data_$(date +%Y%m%d).tar.gz /storage/data/linkwarden
   ```

### Upgrade Procedure

1. Pull the latest image:
   ```bash
   docker-compose pull linkwarden
   ```

2. Restart the container:
   ```bash
   docker-compose up -d linkwarden
   ```

3. Verify the service is running:
   ```bash
   docker logs linkwarden
   ```

### Security Considerations

- Keep Linkwarden and PostgreSQL container images updated
- Rotate the NEXTAUTH_SECRET periodically
- Review Authentik logs for unauthorized access attempts
- Consider implementing rate limiting for authentication attempts

## Integration with Homelab Infrastructure

- **Monitoring**: Integrated with Uptime Kuma for service monitoring
- **Notifications**: Alerts configured via NTFY
- **Reverse Proxy**: Traefik handles routing and SSL termination
- **Authentication**: Authentik provides SSO capabilities
- **Automation**: Watchtower manages container updates (excluding database)
