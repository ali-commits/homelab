# Zitadel Login v2 Troubleshooting Guide

## Problem Summary
**Date**: August 8, 2025
**Status**: UNRESOLVED - Login v2 disabled temporarily
**Main Issue**: Login v2 container cannot communicate with Zitadel API due to instance identification problems

## Current Working State
- **Main Zitadel**: ✅ Working at https://zitadel.alimunee.com
- **Admin Console**: ✅ Working
- **Classic Login UI**: ✅ Working at https://zitadel.alimunee.com/ui/login
- **Login v2**: ❌ Disabled due to 500 errors

## Technical Details

### Infrastructure
- **Setup**: Docker Compose behind Traefik v3 reverse proxy behind Cloudflared
- **Domain**: zitadel.alimunee.com (external TLS via Cloudflare)
- **Database**: PostgreSQL 17-alpine
- **Zitadel Version**: latest (ghcr.io/zitadel/zitadel:latest)
- **Login UI Version**: latest (ghcr.io/zitadel/zitadel-login:latest)

### Root Cause Analysis
The core issue is **instance identification** in Zitadel's multi-tenant architecture:

1. **Problem**: Login v2 container cannot identify the correct Zitadel instance when making API calls
2. **Error Pattern**: `unable to set instance using origin {HOST} (ExternalDomain is zitadel.alimunee.com): Instance not found`
3. **Root Cause**: Zitadel requires the correct `Host` header to match the configured ExternalDomain

### Attempted Solutions

#### 1. Internal Service Communication (FAILED)
```yaml
environment:
  - ZITADEL_API_URL=http://zitadel:8080
```
**Result**: Login container sends `Host: zitadel:8080`, Zitadel rejects (expects `zitadel.alimunee.com`)

#### 2. Custom Host Header (FAILED)
```yaml
environment:
  - ZITADEL_API_URL=http://zitadel:8080
  - ZITADEL_API_HOST_HEADER=zitadel.alimunee.com
```
**Result**: Environment variable ignored by login container

#### 3. Public API URL (FAILED)
```yaml
environment:
  - ZITADEL_API_URL=https://zitadel.alimunee.com
```
**Result**: Still produces instance identification errors

#### 4. Network Mode Changes (FAILED)
- Tried `network_mode: service:zitadel` → caused localhost issues
- Tried separate networks with Traefik labels → routing problems

### Configuration Files

#### Working docker-compose.yml (Login v2 disabled)
```yaml
services:
  zitadel:
    restart: unless-stopped
    image: ghcr.io/zitadel/zitadel:latest
    container_name: zitadel
    command: start-from-init --steps /current-dir/init-config.yaml --masterkey "eb2af57bbab0f9c5cc3d6f457a8a7a5b" --tlsMode external
    environment:
      ZITADEL_EXTERNALDOMAIN: zitadel.alimunee.com
      ZITADEL_EXTERNALSECURE: false
      ZITADEL_TLS_ENABLED: false
      # ... database config ...
      ZITADEL_DEFAULTINSTANCE_FEATURES_LOGINV2_REQUIRED: false
      ZITADEL_DEFAULTINSTANCE_FEATURES_LOGINV2_BASEURI: https://zitadel.alimunee.com/ui/v2/login
    # ... rest of zitadel service config ...
```

#### Service Users Created
- **Admin Service Account**: `zitadel-admin-sa` (Active, has PAT)
- **Login UI Client**: `zitadel-login-client` (Active, has PAT)

#### PAT Files Status
- **admin.pat**: Not present/needed for current setup
- **login-client.pat**: Created manually, contains valid PAT, proper permissions (1000:1000, 640)

### Error Logs (Last Attempt)
```
Error [ConnectError]: [not_found] unable to set instance using origin &{zitadel:8080  https} (ExternalDomain is zitadel.alimunee.com): ID=QUERY-1kIjX Message=Instance not found. Make sure you got the domain right. Check out https://zitadel.com/docs/apis/introduction#domains Parent=(unable to get instance by host: instanceHost zitadel:8080, publicHost : ID=QUERY-1kIjX Message=Errors.IAM.NotFound)
```

## Potential Future Solutions

### 1. Custom Nginx Sidecar
Add an nginx container that proxies requests with correct headers:
```yaml
login-proxy:
  image: nginx:alpine
  volumes:
    - ./nginx-login-proxy.conf:/etc/nginx/nginx.conf
  # Proxy http://login-proxy -> http://zitadel:8080 with Host: zitadel.alimunee.com
```

### 2. Zitadel Configuration Changes
Research if there are Zitadel config options to:
- Allow multiple hostnames for instance identification
- Disable strict host checking for internal services
- Configure instance mapping differently

### 3. Login v2 Container Environment
Investigate other environment variables that might control host header behavior:
- Check Zitadel login v2 source code
- Look for undocumented environment variables
- Test with different Next.js configuration

### 4. Traefik Internal Routing
Create internal Traefik routes that ensure proper headers:
- Internal service discovery for login->zitadel communication
- Custom middleware to inject correct headers

## How to Re-enable Login v2

### 1. Add Login Service Back
```yaml
  login:
    restart: unless-stopped
    image: ghcr.io/zitadel/zitadel-login:latest
    container_name: zitadel-login
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"
      - "traefik.http.routers.zitadel-login.entrypoints=web"
      - "traefik.http.routers.zitadel-login.rule=Host(\`zitadel.alimunee.com\`) && PathPrefix(\`/ui/v2/login\`)"
      - "traefik.http.routers.zitadel-login.priority=100"
      - "traefik.http.routers.zitadel-login.service=zitadel-login"
      - "traefik.http.routers.zitadel-login.middlewares=zitadel-headers"
      - "traefik.http.services.zitadel-login.loadbalancer.server.port=3000"
    environment:
      - ZITADEL_API_URL=https://zitadel.alimunee.com  # OR try internal routing solution
      - NEXT_PUBLIC_BASE_PATH=/ui/v2/login
      - ZITADEL_SERVICE_USER_TOKEN_FILE=/current-dir/login-client.pat
    user: "${UID:-1000}"
    networks:
      - proxy
      - zitadel_internal
    volumes:
      - /storage/data/zitadel/config:/current-dir:ro
    depends_on:
      zitadel:
        condition: service_healthy
```

### 2. Enable in Console
- Console → Settings → Login → Toggle "Login v2" ON

### 3. Test
- https://zitadel.alimunee.com/ui/v2/login should work without 500 errors

## References
- [Zitadel Domains Documentation](https://zitadel.com/docs/apis/introduction#domains)
- [Zitadel Login v2 GitHub](https://github.com/zitadel/login-ui)
- Service User PAT: `vhAlI7boHVyuJMVvhdpnMsJJOnN5iFfBT8YkduCydsh9M_EIjpdDlvwb4NcRpTJrkMoxCrc`

## Notes
- Classic login UI works perfectly - no functionality lost
- All user data, settings, and configuration preserved
- Login v2 is mainly a UX improvement, not a functional requirement
- Issue is purely related to container-to-container communication and host headers
