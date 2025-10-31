# Stirling PDF

## Purpose
Stirling PDF is a robust, locally hosted web-based PDF manipulation tool that provides comprehensive PDF processing capabilities. It offers over 50 features including splitting, merging, converting, reorganizing, compressing, OCR, digital signing, and more, all while maintaining privacy and security.

## Configuration

| Variable         | Description                          | Default | Required |
| ---------------- | ------------------------------------ | ------- | -------- |
| SECURITY_ENABLED | Enable login and security features   | false   | No       |
| ADMIN_USERNAME   | Admin username (if security enabled) | admin   | No       |
| ADMIN_PASSWORD   | Admin password (if security enabled) | -       | No       |

### Ports
- **8080**: Web interface (HTTPS via Traefik)

### Domains
- **External**: https://pdf.alimunee.com
- **Internal**: http://stirling-pdf:8080

## Dependencies
- **Networks**: proxy (for Traefik routing)
- **Storage**: /storage/data/stirling-pdf/ (configuration, logs, tessdata, custom files)

## Setup

1. **Deploy the service**:
   ```bash
   cd services/stirling-pdf
   docker compose up -d
   ```

2. **Initial configuration**:
   - Access https://pdf.alimunee.com
   - No authentication required by default
   - All PDF tools are immediately available

3. **Optional: Enable Security**:
   ```bash
   # Edit .env file
   SECURITY_ENABLED=true
   ADMIN_USERNAME=admin
   ADMIN_PASSWORD=SecurePassword123!

   # Restart service
   docker compose down && docker compose up -d
   ```

4. **Configure OCR Languages** (optional):
   - Download additional Tesseract language packs
   - Place in `/storage/data/stirling-pdf/tessdata/`
   - Restart container to recognize new languages

## Usage

### Web Interface
- **URL**: https://pdf.alimunee.com
- **Features**: 50+ PDF manipulation tools organized by category

### Core Features

#### **Convert & Transform**
- PDF to/from images (PNG, JPG, TIFF)
- PDF to/from Office formats (Word, Excel, PowerPoint)
- HTML to PDF conversion
- Markdown to PDF

#### **Organize & Edit**
- Split PDFs by page ranges or bookmarks
- Merge multiple PDFs
- Rotate, rearrange, and remove pages
- Extract pages or images

#### **Security & Privacy**
- Add/remove passwords and permissions
- Digital signing with certificates
- Redact sensitive information
- Watermark addition

#### **OCR & Text**
- OCR processing for scanned documents
- Text extraction and search
- Language detection and processing
- Font and text manipulation

#### **Optimize & Compress**
- File size reduction and compression
- Image quality optimization
- Remove metadata and annotations
- Clean up and repair corrupted PDFs

### API Access
- **REST API**: Available at https://pdf.alimunee.com/api/
- **Swagger Documentation**: https://pdf.alimunee.com/swagger-ui.html
- **Batch Processing**: Programmatic PDF manipulation

## Integration

### OCR Configuration
```bash
# Download additional language packs
cd /storage/data/stirling-pdf/tessdata/
wget https://github.com/tesseract-ocr/tessdata/raw/main/fra.traineddata  # French
wget https://github.com/tesseract-ocr/tessdata/raw/main/deu.traineddata  # German
wget https://github.com/tesseract-ocr/tessdata/raw/main/spa.traineddata  # Spanish

# Restart container
docker compose restart stirling-pdf
```

### Custom Branding
- **Logo**: Place custom logo in `/storage/data/stirling-pdf/customFiles/static/`
- **CSS**: Custom styling in `/storage/data/stirling-pdf/customFiles/static/`
- **Favicon**: Custom favicon in customFiles directory

### Monitoring
- **Health Check**: Built-in API status endpoint
- **Uptime Kuma**: Monitor https://pdf.alimunee.com
- **ntfy Topic**: `homelab-alerts` for service issues

### Workflow Integration
- **API Integration**: Use REST API for automated PDF processing
- **Batch Processing**: Process multiple files programmatically
- **Webhook Support**: Trigger processing from other services

## Troubleshooting

### Common Issues

1. **Memory Issues with Large Files**:
   ```bash
   # Check memory usage
   docker stats stirling-pdf

   # Increase memory limit in docker-compose.yml
   deploy:
     resources:
       limits:
         memory: 4G
   ```

2. **OCR Not Working**:
   ```bash
   # Check tessdata directory
   ls -la /storage/data/stirling-pdf/tessdata/

   # Verify language files
   docker exec stirling-pdf ls -la /usr/share/tessdata/

   # Test OCR functionality
   docker exec stirling-pdf tesseract --list-langs
   ```

3. **File Upload Issues**:
   ```bash
   # Check file size limits
   docker logs stirling-pdf | grep -i "file size"

   # Verify volume permissions
   sudo chown -R 1000:1000 /storage/data/stirling-pdf/
   ```

4. **Performance Problems**:
   ```bash
   # Monitor resource usage
   docker stats stirling-pdf

   # Check processing logs
   docker compose logs -f stirling-pdf

   # Clear temporary files
   docker exec stirling-pdf find /tmp -name "*.pdf" -delete
   ```

### Debug Commands
```bash
# View application logs
docker compose logs -f stirling-pdf

# Check service status
curl -f http://localhost:8080/api/v1/info/status

# Test API endpoints
curl -X GET "https://pdf.alimunee.com/api/v1/info/status"

# Monitor file processing
docker exec stirling-pdf tail -f /logs/stirling-pdf.log

# Check available features
curl -X GET "https://pdf.alimunee.com/api/v1/info/endpoints"
```

### Performance Optimization
```bash
# Adjust JVM memory settings (if needed)
# Add to environment in docker-compose.yml:
# - JAVA_OPTS=-Xmx2g -Xms512m

# Monitor heap usage
docker exec stirling-pdf jstat -gc 1

# Clear cache and temporary files
docker exec stirling-pdf find /tmp -type f -name "*.tmp" -delete
```

## Backup

### Configuration Backup
```bash
# Backup Stirling PDF configuration and data
sudo tar -czf stirling-pdf-$(date +%Y%m%d).tar.gz -C /storage/data stirling-pdf/

# Backup specific components
sudo tar -czf stirling-config-$(date +%Y%m%d).tar.gz -C /storage/data/stirling-pdf config/
sudo tar -czf stirling-tessdata-$(date +%Y%m%d).tar.gz -C /storage/data/stirling-pdf tessdata/
```

### Restore Configuration
```bash
# Restore full backup
sudo tar -xzf stirling-pdf-YYYYMMDD.tar.gz -C /storage/data/

# Fix permissions
sudo chown -R 1000:1000 /storage/data/stirling-pdf/

# Restart service
docker compose restart stirling-pdf
```

### Custom Files Backup
```bash
# Backup custom branding and files
sudo tar -czf stirling-custom-$(date +%Y%m%d).tar.gz -C /storage/data/stirling-pdf customFiles/

# Restore custom files
sudo tar -xzf stirling-custom-YYYYMMDD.tar.gz -C /storage/data/stirling-pdf/
```

## Security Considerations

### Authentication Setup
```bash
# Enable security in .env
SECURITY_ENABLED=true
ADMIN_USERNAME=admin
ADMIN_PASSWORD=SecurePassword123!

# Restart with security enabled
docker compose down && docker compose up -d
```

### Network Security
- Service runs behind Traefik reverse proxy with HTTPS
- No direct external port exposure
- Internal network isolation
- File processing happens locally (no external API calls)

### Data Privacy
- All PDF processing happens locally
- No data sent to external services
- Temporary files are automatically cleaned
- No persistent storage of processed files unless explicitly saved

### File Security
- Input validation for uploaded files
- Sandboxed processing environment
- Resource limits to prevent DoS
- Automatic cleanup of temporary files
