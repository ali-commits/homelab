# Cloudflared

**Purpose**: Cloudflare Tunnel for secure remote access

**Configuration**: Token-based tunnel configuration managed through Cloudflare Zero Trust portal

| Configuration      | Details                                                                    |
| ------------------ | -------------------------------------------------------------------------- |
| Configuration Type | Token-based (managed via CF portal)                                        |
| Token File         | `.env` - Contains tunnel token                                             |
| Tunnel ID          | `becc60fe-112e-4d4f-b662-805f156651cb`                                     |
| DNS Configuration  | `*.alimunee.com` → `becc60fe-112e-4d4f-b662-805f156651cb.cfargotunnel.com` |
| External Access    | All *.alimunee.com subdomains (instant DNS)                                |
| TLS                | Handled by Cloudflare                                                      |

## 🌟 **Wildcard DNS Configuration**

**DNS Record**: `*.alimunee.com` CNAME → `becc60fe-112e-112e-4d4f-b662-805f156651cb.cfargotunnel.com`

**Benefits**:
- ✅ **Instant Subdomains**: Any new subdomain added in CF portal works immediately
- ✅ **No Manual DNS**: No need to create individual DNS records
- ✅ **Scalable**: Unlimited subdomains without DNS management
- ✅ **Portal Managed**: All routing managed through Cloudflare Zero Trust portal

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

### **.env** - Tunnel Token
Contains the tunnel authentication token. **Keep this file secure!**
```
CLOUDFLARED_TUNNEL_TOKEN=eyJhIjoiNjAwMzMwNjhmMzk1YjQzNzQ3OWUzYmY4NzNlM2Q2OGUi...
```

## 🔧 **Adding New Services**

### **Method: Cloudflare Zero Trust Portal**
1. Navigate to [Cloudflare Zero Trust](https://dash.cloudflare.com) → Networks → Tunnels
2. Find tunnel `becc60fe-112e-4d4f-b662-805f156651cb` and click **Configure**
3. Go to **Public Hostnames** tab and click **Add a public hostname**
4. Configure:
   - **Subdomain**: `myservice`
   - **Domain**: `alimunee.com`
   - **Service**: Choose appropriate type (HTTP/HTTPS)
   - **URL**: Target service (e.g., `traefik:80` or `192.168.1.2:9090`)
5. **DNS works instantly** via wildcard CNAME!

### **Service Type Guidelines**
- **Traefik-routed services**: HTTP → `traefik:80`
- **Direct HTTPS services**: HTTPS → `192.168.1.2:port` (enable "No TLS Verify")
- **Direct HTTP services**: HTTP → `192.168.1.2:port`

## 📋 **Current Architecture**

```
Internet → Cloudflare DNS (*.alimunee.com) → Tunnel → Services
                                               ↓
┌─────────────────────────────────────────────┴─────────────────────────────────────────────┐
│                          Tunnel Configuration (CF Portal)                                  │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│ traefik.alimunee.com     → traefik:8080     (Direct dashboard access)                    │
│ cockpit.alimunee.com     → 192.168.1.2:9090 (Direct host service - HTTPS + No TLS)      │
│ ALL other subdomains     → traefik:80       (Routed by Traefik reverse proxy)            │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## ✅ **Current Working Services**

| Subdomain                    | Target           | Type                  | Status    |
| ---------------------------- | ---------------- | --------------------- | --------- |
| **cockpit.alimunee.com**     | 192.168.1.2:9090 | HTTPS (No TLS Verify) | ✅ Working |
| **traefik.alimunee.com**     | traefik:8080     | HTTP                  | ✅ Working |
| **All other *.alimunee.com** | traefik:80       | HTTP                  | ✅ Working |

## 📋 **Service Mappings**

| Category           | Subdomain Pattern    | Target           | Purpose                           |
| ------------------ | -------------------- | ---------------- | --------------------------------- |
| **Direct Access**  | traefik.alimunee.com | traefik:8080     | Traefik dashboard                 |
| **Host Services**  | cockpit.alimunee.com | 192.168.1.2:9090 | Server management                 |
| **Traefik-Routed** | All others           | traefik:80       | Docker services via reverse proxy |

### **Traefik-Routed Services** (via http://traefik:80)
- **Core**: auth.alimunee.com, adguard.alimunee.com, status.alimunee.com, notification.alimunee.com
- **Media**: tv.alimunee.com, sonarr.alimunee.com, radarr.alimunee.com, prowlarr.alimunee.com, bazarr.alimunee.com, qbit.alimunee.com, request.alimunee.com
- **Cloud**: cloud.alimunee.com, photos.alimunee.com, notes.alimunee.com, links.alimunee.com
- **Utility**: All configured subdomains in portal

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
# Any subdomain resolves instantly via wildcard!
dig myservice.alimunee.com

# Check if service responds
curl -I https://myservice.alimunee.com
```

### **Common Issues & Solutions**

| Issue                 | Symptom                  | Solution                                                  |
| --------------------- | ------------------------ | --------------------------------------------------------- |
| **Redirect Loop**     | `ERR_TOO_MANY_REDIRECTS` | Change service type from HTTP to HTTPS in portal          |
| **Connection Failed** | `502 Bad Gateway`        | Verify target service is running and accessible           |
| **DNS Not Resolving** | Domain not found         | Wildcard CNAME should handle all subdomains automatically |

### **Important Configuration Notes**

- **Cockpit**: Must use HTTPS service type with "No TLS Verify" enabled
- **Traefik Services**: Use HTTP service type pointing to `traefik:80`
- **Direct Host Services**: Check if service runs HTTP or HTTPS first
- **Token-based**: All configuration changes made in Cloudflare Zero Trust portal
