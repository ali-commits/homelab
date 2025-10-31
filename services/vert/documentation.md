# VERT

## Purpose
VERT is a self-hosted filn service that provides client-side file format conversion with privacy-focused processing. It uses WebAssembly to convert files the user's browser, supporting 250+ formats including documents, images, audio, and video without uploading files to any server.

## Configuration

| Variable            | Description                  | Default | Required |
| ------------------- | ---------------------------- | ------- | -------- |
| SERVICE_NAME        | Service display name         | VERT    | No       |
| SERVICE_URL         | External URL for the service | -       | No       |
| SERVICE_DESCRIPTION | Service description          | -       | No       |

### Ports
- **80**: Web interface (HTTPS via Traefik)

### Domains
- **External**: https://convert.alimunee.com
- **Internal**: http://vert:80

## Dependencies
- **Networks**: proxy (for Traefik routing)
- **Storage**: No persistent storage required (client-side processing)

## Setup

1. **Deploy the service**:
   ```bash
   cd services/vert
   docker compose up -d
   ```

2. **Verify deployment**:
   ```bash
   # Check container status
   docker ps | grep vert

   # Check logs
   docker compose logs -f vert

   # Test health endpoint
   curl -f http://localhost:80/
   ```

3. **Access the service**:
   - Navigate to https://convert.alimunee.com
   - Upload files for conversion (processed in browser)
   - Download converted files

## Usage

### Web Interface
- **URL**: https://convert.alimunee.com
- **Features**: Drag-and-drop file conversion interface with WebAssembly processing

### Supported Formats

#### **Document Conversion**
- **Input**: PDF, DOC, DOCX, RTF, TXT, ODT, EPUB
- **Output**: PDF, DOC, DOCX, TXT, HTML, ODT
- **Use Cases**: Document format standardization, legacy format conversion

#### **Image Conversion**
- **Input**: JPG, JPEG, PNG, GIF, BMP, TIFF, WEBP, SVG, ICO
- **Output**: JPG, PNG, GIF, BMP, TIFF, WEBP, PDF, SVG
- **Use Cases**: Image optimization, format compatibility, batch processing

#### **Audio Conversion**
- **Input**: MP3, WAV, FLAC, AAC, OGG, M4A, WMA
- **Output**: MP3, WAV, FLAC, AAC, OGG
- **Use Cases**: Audio format conversion, quality adjustment

#### **Video Conversion** (via daemon)
- **Input**: MP4, AVI, MOV, MKV, WMV, FLV, WEBM
- **Output**: MP4, AVI, MOV, MKV, WEBM
- **Note**: Video conversion requires the VERT daemon for server-side processing

### Conversion Process
1. **Upload**: Drag and drop files or click to browse
2. **Select Format**: Choose target format from dropdown
3. **Configure**: Adjust quality/compression settings (if available)
4. **Convert**: Processing happens in your browser using WebAssembly
5. **Download**: Download converted files immediately

### Key Features
- **Client-Side Processing**: All conversions happen in your browser
- **Privacy-First**: No files uploaded to servers
- **No File Size Limits**: Convert files of any size
- **Batch Processing**: Convert multiple files simultaneously
- **Offline Capable**: Works without internet connection
- **Cross-Platform**: Works on any device with a modern browser

## Integration

### Privacy Benefits
- **No Server Upload**: Files never leave your device
- **Local Processing**: WebAssembly runs conversion locally
- **No Data Collection**: No tracking or analytics
- **Offline Operation**: Works without internet connection

### Workflow Integration
- **Nextcloud**: Convert files before uploading to cloud storage
- **Paperless-ngx**: Convert documents before OCR processing
- **Media Stack**: Convert video/audio formats for compatibility
- **Development**: Convert assets and media files for projects

### Monitoring
- **Health Check**: Built-in endpoint at `/`
- **Uptime Kuma**: Monitor https://convert.alimunee.com
- **ntfy Topic**: `homelab-alerts` for service issues
- **Metrics**: Service availability and response times

### Performance Optimization
```bash
# VERT is lightweight and requires minimal resources
# Default memory limits are sufficient for most use cases
deploy:
  resources:
    limits:
      memory: 512M
    reservations:
      memory: 128M
```

## Troubleshooting

### Common Issues

1. **Service Not Accessible**:
   ```bash
   # Check container status
   docker ps | grep vert

   # Check Traefik routing
   docker logs traefik | grep vert

   # Test direct access
   curl -f http://localhost:80/
   ```

2. **Conversion Failures in Browser**:
   ```bash
   # Check browser console for WebAssembly errors
   # Ensure modern browser with WebAssembly support
   # Try different file formats or smaller files

   # Verify service is serving files correctly
   curl -I https://convert.alimunee.com/
   ```

3. **Performance Issues**:
   ```bash
   # Monitor resource usage
   docker stats vert

   # Check nginx logs
   docker compose logs -f vert

   # Verify browser performance (client-side processing)
   ```

4. **Memory Issues**:
   ```bash
   # Increase memory limits if needed
   # Edit docker-compose.yml memory limits
   docker compose down && docker compose up -d

   # Monitor memory usage
   docker exec vert free -h
   ```

### Debug Commands
```bash
# View application logs
docker compose logs -f vert

# Check service health
curl -f https://convert.alimunee.com/

# Test nginx configuration
docker exec vert nginx -t

# Monitor file serving
docker exec vert tail -f /var/log/nginx/access.log

# Check WebAssembly files are served correctly
curl -I https://convert.alimunee.com/wasm/
```

### Performance Tuning
```bash
# VERT is optimized for client-side processing
# Server-side tuning is minimal since processing happens in browser

# Monitor nginx performance
docker exec vert tail -f /var/log/nginx/access.log

# Check for any server errors
docker exec vert tail -f /var/log/nginx/error.log
```

## Backup

### Configuration Backup
```bash
# Backup VERT service configuration
sudo tar -czf vert-$(date +%Y%m%d).tar.gz -C services vert/

# Note: No data backup needed as VERT doesn't store user files
```

### Reore Configuration
```bash
# Restore service configuration
sudo tar -xzf vert-YYYYMMDD.tar.gz -C services/

# Restartrvice
docker compose -f services/vert/docker-compose.yml restart
```

### No Data Backup Required
- VERT processes files client-side in the browser
- No user files are stored on the server
- Only service configuration needs backup

## Security Considerations

### Privacy Features
- **Client-Side Processing**: All conversions happen in the user's browser
- **No File Upload**: Files never leave the user's device
- **No Data Collection**: No tracking, analytics, or user data storage
- **WebAssembly Security**: Sandboxed execution environment

### Network Security
- Service runs behind Traefik reverse proxy with HTTPS
- No direct external port exposure
- Internal network isolation
- Static file serving only (no dynamic server-side processing)

### Data Privacy
- **Zero Server Storage**: No user files stored on server
- **Local WebAssembly Processing**: All conversion logic runs locally
- **No External Dependencies**: No third-party API calls
- **Offline Capable**: Works without internet connection

### Access Control
- No authentication required (client-side processing)
- Rate limiting handled by Traefik
- DDoS protection via Cloudflare
- No sensitive server-side operations

## Advanced Configuration

### WebAssembly Optimization
```bash
# VERT automatically optimizes WebAssembly loading
# No server-side configuration needed
# Browser handles WebAssembly compilation and execution
```

### Integration with Other Services
```bash
# VERT works as a standalone service
# No database or external service dependencies
# Can be used alongside other homelab services

# Example: Use with Nextcloud for file conversion before upload
# Example: Use with Paperless-ngx for document format standardization
```

### Monitoring and Alerts
```bash
# Set up service monitoring
# Add to Uptime Kuma:
# - URL: https://convert.alimunee.com/
# - Method: GET
# - Expected Status: 200

# ntfy notifications for service downtime
# Service will be monitored for availability only
```

### Video Conversion Setup (Optional)
For video conversion capabilities, you can deploy the VERT daemon (vertd):

```bash
# Clone and setup VERT daemon for video processing
git clone https://github.com/VERT-sh/vertd
cd vertd
# Follow setup instructions for server-side video conversion
```

## Comparison with Other Converters

### VERT vs Server-Side Converters
- **Privacy**: VERT processes files locally vs server upload
- **Speed**: No upload/download time, instant processing
- **Limits**: No file size limits vs server storage constraints
- **Offline**: Works offline vs requires internet connection
- **Resources**: Uses client CPU vs server resources

### VERT vs Cloud Services
- **Data Privacy**: Files never leave your device
- **Cost**: Free and self-hosted vs subscription fees
- **Availability**: Always available vs service dependencies
- **Customization**: Full control vs limited options
