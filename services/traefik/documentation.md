# Traefik

**Purpose**: Edge router and reverse proxy for all homelab services

## Configuration

| Variable  | Description            | Default            | Required |
| --------- | ---------------------- | ------------------ | -------- |
| Version   | Traefik version        | v3.5               | Yes      |
| Dashboard | Web UI access          | Port 8080          | No       |
| TLS       | Certificate management | Let's Encrypt ACME | Yes      |
| Networks  | Docker networks        | proxy              | Yes      |

## Dependencies

- **Networks**: `proxy` (external)
- **Storage**: `/storage/data/letsencrypt` for ACME certificates
- **Ports**: 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)

## Setup

1. Ensure proxy network exists:
   ```bash
   docker network create proxy
   ```

2. Deploy Traefik:
   ```bash
   docker compose -f services/traefik/docker-compose.yml up -d
   ```

## Usage

- **Dashboard**: http://192.168.1.2:8080 (internal access only)
- **HTTP Entry**: Port 80 (redirects to HTTPS)
- **HTTPS Entry**: Port 443 (main entry point)
- **Certificate Storage**: `/storage/data/letsencrypt/acme.json`

## Features (v3.5)

- **OCSP Stapling**: Enhanced TLS security
- **Post-Quantum TLS**: X25519MLKEM768 support
- **React Dashboard**: Modern web interface
- **Enhanced Health Checks**: Improved service monitoring
- **NGINX Ingress Provider**: Additional provider support

## Experimental Plugins

| Plugin                | Version | Purpose                                   |
| --------------------- | ------- | ----------------------------------------- |
| **Sablier**           | v1.10.1 | Dynamic container scaling and hibernation |
| **Traefik OIDC Auth** | v0.16.0 | OpenID Connect authentication middleware  |
| **Cloudflare Warp**   | v1.3.3  | Cloudflare Zero Trust integration         |



## Integration

All services use Traefik labels for automatic discovery:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.service.rule=Host(`service.alimunee.com`)"
  - "traefik.docker.network=proxy"
```

## Monitoring

- Health status visible in dashboard
- Access logs enabled for debugging
- Debug logging level for troubleshooting
