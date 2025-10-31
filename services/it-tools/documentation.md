# IT-Tools

## Purpose
IT-Tools is a self-hosted collection of handy online tools for developers and IT professionals. It provides a clean, user-friendly web interface with various utilities for encoding/decoding, hashing, formatting, text manipulation, and other common development tasks.

## Configuration

| Variable | Description | Default          | Required |
| -------- | ----------- | ---------------- | -------- |
| TZ       | Timezone    | America/New_York | No       |

### Ports
- **80**: Web interface (HTTPS via Traefik)

### Domains
- **External**: https://tools.alimunee.com
- **Internal**: http://it-tools:80

## Dependencies
- **Networks**: proxy (for Traefik routing)
- **Storage**: No persistent storage required (stateless application)

## Setup

1. **Deploy the service**:
   ```bash
   cd services/it-tools
   docker compose up -d
   ```

2. **Access the interface**:
   - Navigate to https://tools.alimunee.com
   - No initial configuration required - ready to use immediately

## Usage

### Web Interface
- **URL**: https://tools.alimunee.com
- **Features**: Collection of developer and IT utilities

### Available Tools

#### **Encoders & Decoders**
- Base64 encode/decode
- URL encode/decode
- HTML entities encode/decode
- JWT decoder
- Hash generators (MD5, SHA1, SHA256, etc.)

#### **Formatters & Validators**
- JSON formatter and validator
- YAML formatter and validator
- XML formatter and validator
- SQL formatter
- CSS formatter

#### **Text & String Tools**
- Text case converters (uppercase, lowercase, camelCase, etc.)
- Text diff comparison
- Lorem ipsum generator
- String length calculator
- Regex tester

#### **Generators**
- UUID/GUID generator
- Password generator
- QR code generator
- Barcode generator
- Random data generators

#### **Converters**
- Color converter (HEX, RGB, HSL)
- Unit converters
- Number base converters
- Date/time converters

#### **Network & Security**
- IP address tools
- Port scanner
- SSL certificate checker
- DNS lookup tools

## Integration

### API Access
- IT-Tools is primarily a web-based toolkit
- Most tools work client-side in the browser
- No API endpoints for programmatic access

### Bookmarking
- Individual tools can be bookmarked for quick access
- Clean URLs for each utility
- Responsive design works on mobile devices

### Monitoring
- **Health Check**: Built-in HTTP health endpoint
- **Uptime Kuma**: Monitor https://tools.alimunee.com
- **ntfy Topic**: `homelab-alerts` for service issues

## Troubleshooting

### Common Issues

1. **Service Not Loading**:
   ```bash
   # Check container status
   docker compose logs -f it-tools

   # Verify container is running
   docker compose ps
   ```

2. **Tools Not Working**:
   - Most tools run client-side in JavaScript
   - Check browser console for JavaScript errors
   - Ensure modern browser with JavaScript enabled

3. **Performance Issues**:
   ```bash
   # Monitor resource usage
   docker stats it-tools

   # Check memory limits
   docker inspect it-tools | jq '.[0].HostConfig.Memory'
   ```

### Debug Commands
```bash
# View application logs
docker compose logs -f it-tools

# Test direct container access
curl -I http://localhost:80

# Check Traefik routing
curl -s http://localhost:8080/api/http/routers | jq '.[] | select(.name | contains("it-tools"))'

# Verify container health
docker inspect it-tools | jq '.[0].State.Health'
```

### Performance Optimization
```bash
# The service is lightweight and stateless
# Resource usage should be minimal
# Most processing happens client-side

# Monitor memory usage
docker stats it-tools --no-stream
```

## Backup

### No Backup Required
- **Stateless Application**: IT-Tools doesn't store any user data
- **No Configuration**: No persistent configuration to backup
- **Container Only**: Simply redeploy from image if needed

### Recovery Steps
1. **Simple Redeployment**:
   ```bash
   cd services/it-tools
   docker compose down
   docker compose pull
   docker compose up -d
   ```

2. **No Data Recovery Needed**: All tools work client-side with no server-side storage

## Security Considerations

### Privacy Benefits
- **Self-Hosted**: All tools run locally, no data sent to external services
- **Client-Side Processing**: Most operations happen in your browser
- **No Data Storage**: No sensitive data stored on server
- **Network Isolation**: Runs behind Traefik reverse proxy

### Access Control
- Currently no built-in authentication
- Access controlled by network (internal homelab)
- Consider adding Traefik middleware for authentication if needed

### Data Security
- All processing happens locally
- No external API calls for sensitive operations
- Safe for processing confidential data (passwords, tokens, etc.)

## Use Cases

### Development Workflow
- Format and validate JSON/YAML configurations
- Generate UUIDs for database records
- Encode/decode API tokens and credentials
- Test regular expressions
- Convert between different data formats

### System Administration
- Generate secure passwords
- Create QR codes for WiFi credentials
- Convert between different number systems
- Validate and format configuration files
- Quick hash generation for file verification

### Daily Utilities
- Color picker and converter for web design
- Text case conversion for documentation
- Lorem ipsum generation for mockups
- Unit conversions for various measurements
