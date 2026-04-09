# Cloudflared

**Purpose**: Cloudflare Tunnel for secure remote access

**Configuration**: Token-based tunnel with `flared` CLI for route and DNS management

| Configuration      | Details                                    |
| ------------------ | ------------------------------------------ |
| Configuration Type | Token-based (managed via `flared` CLI or CF portal) |
| Credentials        | `.env` - Contains tunnel token and API keys |
| Tunnel ID          | Stored in `.env` as `CF_TUNNEL_ID`          |
| DNS Configuration  | Per-subdomain CNAME records (Cloudflare free tier) |
| TLS                | Handled by Cloudflare                       |

## 📁 **Configuration Files**

### **docker-compose.yml** - Container Configuration

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token ${CLOUDFLARED_TUNNEL_TOKEN}
    env_file:
      - .env
    dns:
       - 1.1.1.1
       - 8.8.8.8
    networks:
      - proxy
```

### **.env** - Credentials

Contains the tunnel token, API token, and tunnel metadata. **Keep this file secure!**

| Variable                 | Description                          | How to obtain |
| ------------------------ | ------------------------------------ | ------------- |
| `CLOUDFLARED_TUNNEL_TOKEN` | Tunnel daemon authentication token | Cloudflare Zero Trust → Networks → Tunnels → your tunnel → Configure → Install connector |
| `CF_API_TOKEN`           | API token for `flared` CLI           | See [Creating an API Token](#creating-an-api-token) below |
| `CF_ACCOUNT_ID`          | Cloudflare account ID                | Encoded in the tunnel token (decode with `echo $CLOUDFLARED_TUNNEL_TOKEN \| base64 -d \| jq .a`) |
| `CF_TUNNEL_ID`           | Tunnel UUID                          | Encoded in the tunnel token (decode with `echo $CLOUDFLARED_TUNNEL_TOKEN \| base64 -d \| jq .t`) |
| `CF_DOMAIN`              | Base domain for subdomains           | `alimunee.com` |

### **Creating an API Token**

The `flared` CLI requires a Cloudflare API token to manage tunnel routes and DNS records.

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click **Create Token** → **Custom Token** → **Get started**
3. Set permissions:
   - **Account** → **Cloudflare Tunnel** → **Edit**
   - **Zone** → **DNS** → **Edit**
4. Set resources:
   - Account Resources: **Include** → your account
   - Zone Resources: **Include** → **Specific zone** → `alimunee.com`
5. Click **Continue to summary** → **Create Token**
6. Copy the token (only shown once) and save it as `CF_API_TOKEN` in `.env`

## 🔧 **Adding New Services**

### **Method 1: `flared` CLI (Recommended)**

The `flared` script manages tunnel public hostnames via the Cloudflare API. It's installed globally and also symlinked at `services/cloudflared/flared`.

```bash
# List all current routes
flared list

# Add a new subdomain (defaults to http://traefik)
flared add myservice

# Add with a custom target and protocol
flared add cockpit 192.168.1.2:9090 https

# Remove a route
flared delete myservice
```

Credentials are loaded from `.env` in this directory (`CF_API_TOKEN`, `CF_ACCOUNT_ID`, `CF_TUNNEL_ID`, `CF_DOMAIN`).

### **Method 2: Cloudflare Zero Trust Portal**

1. Navigate to [Cloudflare Zero Trust](https://dash.cloudflare.com) → Networks → Tunnels
2. Find tunnel `becc60fe-112e-4d4f-b662-805f156651cb` and click **Configure**
3. Go to **Public Hostnames** tab and click **Add a public hostname**
4. Configure:
   - **Subdomain**: `myservice`
   - **Domain**: `alimunee.com`
   - **Service**: Choose appropriate type (HTTP/HTTPS)
   - **URL**: Target service (e.g., `traefik:80` or `192.168.1.2:9090`)

### **Service Type Guidelines**
- **Traefik-routed services**: HTTP → `traefik:80`
- **Direct HTTPS services**: HTTPS → `192.168.1.2:port` (enable "No TLS Verify")
- **Direct HTTP services**: HTTP → `192.168.1.2:port`

## 📋 **Current Architecture**

```
Internet → Cloudflare DNS (subdomain.alimunee.com) → Tunnel → Services
                                                        ↓
┌───────────────────────────────────────────────────────┴───────────────────────────────┐
│                     Tunnel Configuration (flared CLI / CF Portal)                      │
├───────────────────────────────────────────────────────────────────────────────────────┤
│ Each subdomain has a CNAME record → <tunnel-id>.cfargotunnel.com                      │
│ traefik.alimunee.com     → traefik:8080     (Direct dashboard access)                 │
│ cockpit.alimunee.com     → 192.168.1.2:9090 (Direct host service - HTTPS + No TLS)   │
│ Most subdomains          → traefik           (Routed by Traefik reverse proxy)         │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

## 📋 **Service Mappings**

| Category          | Subdomain Pattern    | Target           | Purpose                           |
| ----------------- | -------------------- | ---------------- | --------------------------------- |
| **Direct Access** | traefik.alimunee.com | traefik:8080     | Traefik dashboard                 |
| **Host Services** | cockpit.alimunee.com | 192.168.1.2:9090 | Server management                 |
| **Traefik-Routed**| All others           | traefik          | Docker services via reverse proxy |

Use `flared list` to see all current routes.

## 🛠️ **Management & Troubleshooting**

### **Service Management**
```bash
# Check container status
docker ps | grep cloudflared

# View logs
docker logs cloudflared --tail 20

# Restart service
cd /HOMELAB/services/cloudflared && docker compose restart

# Test connectivity
curl -I https://cockpit.alimunee.com
```

### **DNS Verification**

```bash
# Check DNS resolution
dig myservice.alimunee.com

# Check if service responds
curl -I https://myservice.alimunee.com
```

### **Common Issues & Solutions**

| Issue                 | Symptom                  | Solution                                                          |
| --------------------- | ------------------------ | ----------------------------------------------------------------- |
| **Redirect Loop**     | `ERR_TOO_MANY_REDIRECTS` | Change service type from HTTP to HTTPS in portal                  |
| **Connection Failed** | `502 Bad Gateway`        | Verify target service is running and accessible                   |
| **DNS Not Resolving** | Domain not found         | Run `flared add <subdomain>` to create both tunnel route and DNS record |
| **DNS Cache Stale**   | `dig` works but `curl` fails | Flush local DNS cache: `resolvectl flush-caches`               |

### **Important Configuration Notes**

- **Cockpit**: Must use HTTPS service type with "No TLS Verify" enabled
- **Traefik Services**: Use HTTP service type pointing to `traefik`
- **Direct Host Services**: Check if service runs HTTP or HTTPS first
- **DNS**: Each subdomain needs a CNAME record — `flared add` creates both the route and DNS automatically
