# Stirling PDF

## Purpose
Stirling PDF is a robust, locally hosted web-based PDF manipulation tool providing 50+ PDF processing features including splitting, merging, converting, reorganizing, compressing, OCR, digital signing, and more — all processed locally with no external API calls.

**Current version**: v2.7.3 (Spring Boot 4, Java 25)

## Configuration

| Variable                        | Description                                       | Required |
| ------------------------------- | ------------------------------------------------- | -------- |
| `ADMIN_USERNAME`                | Initial admin username (used only on first start) | Yes      |
| `ADMIN_PASSWORD`                | Initial admin password (forced change on login)   | Yes      |
| `SECURITY_ENABLELOGIN`          | Enable user authentication (always `true`)        | Yes      |
| `SECURITY_INITIALLOGIN_USERNAME`| Maps to `ADMIN_USERNAME` from .env                | Yes      |
| `SECURITY_INITIALLOGIN_PASSWORD`| Maps to `ADMIN_PASSWORD` from .env                | Yes      |
| `INSTALL_BOOK_AND_ADVANCED_HTML_OPS` | Enable advanced HTML/book operations        | No       |
| `SYSTEM_MAXFILESIZE`            | Max upload size in MB (default: 100)              | No       |
| `MAIL_ENABLED`                  | Enable email (for user invites)                   | No       |
| `MAIL_HOST`                     | SMTP host (postfix)                               | No       |
| `MAIL_PORT`                     | SMTP port (25 for internal Postfix)               | No       |
| `MAIL_FROM`                     | Sender address for invites                        | No       |
| `MAIL_ENABLEINVITES`            | Allow admin to send email invitations             | No       |

> **Note**: `ADMIN_USERNAME`/`ADMIN_PASSWORD` are only used if no user database exists. After first login, manage users via the in-app admin panel.

> **SSO**: OAuth2 SSO requires a paid license — `autoCreateUser` via OAuth2 is blocked on the free tier (`requiresPaid=true`). SAML2 is also Enterprise-only. Local username/password login only on free tier.

### Ports
- **8080**: Web interface (HTTPS via Traefik)

### Domains
- **External**: https://pdf.alimunee.com
- **Internal**: http://stirling-pdf:8080

## Dependencies
- **Networks**: `proxy` (Traefik routing, also reaches Postfix for email)
- **Storage**: `/storage/data/stirling-pdf/` — config, logs, tessdata, pipeline, customFiles
- **Database**: H2 embedded (stored in `/configs`) — no external DB needed

## Volumes

| Host Path                              | Container Path         | Purpose                     |
| -------------------------------------- | ---------------------- | --------------------------- |
| `/storage/data/stirling-pdf/tessdata`  | `/usr/share/tessdata`  | OCR language packs          |
| `/storage/data/stirling-pdf/config`    | `/configs`             | Settings, user DB, JWT keys |
| `/storage/data/stirling-pdf/logs`      | `/logs`                | Application logs            |
| `/storage/data/stirling-pdf/pipeline`  | `/pipeline`            | Automation pipeline configs |
| `/storage/data/stirling-pdf/customFiles` | `/customFiles`       | Custom branding/static files|

## Setup

1. **Deploy the service**:
   ```bash
   cd /HOMELAB/services/stirling-pdf
   docker compose up -d
   ```

2. **First login**:
   - Access https://pdf.alimunee.com
   - Login with credentials from `.env`
   - You will be forced to change your password immediately

3. **Add more users**:
   - Account Settings → Admin Settings → User Management

4. **Configure OCR Languages** (optional):
   ```bash
   cd /storage/data/stirling-pdf/tessdata/
   wget https://github.com/tesseract-ocr/tessdata/raw/main/ara.traineddata  # Arabic
   wget https://github.com/tesseract-ocr/tessdata/raw/main/fra.traineddata  # French
   docker compose restart stirling-pdf
   ```

## Usage

### Web Interface
- **URL**: https://pdf.alimunee.com
- **API**: https://pdf.alimunee.com/api/
- **Swagger**: https://pdf.alimunee.com/swagger-ui.html

### Core Features

#### **Convert & Transform**
- PDF to/from images (PNG, JPG, TIFF)
- PDF to/from Office formats (Word, Excel, PowerPoint)
- HTML to PDF, Markdown to PDF

#### **Organize & Edit**
- Split/merge, rotate, rearrange, extract pages
- Remove or reorder pages

#### **Security & Privacy**
- Add/remove passwords and permissions
- Digital signing with certificates
- Redact sensitive information, watermarks

#### **OCR & Text**
- OCR processing for scanned documents
- Text extraction, font and text manipulation

#### **Optimize & Compress**
- File size reduction, image quality optimization
- Remove metadata, repair corrupted PDFs

### API Authentication
When `SECURITY_ENABLELOGIN=true`, API calls require an API key:
```
X-API-KEY: your-api-key-here
```
Find your API key in: Account Settings → API Key

## Troubleshooting

### Common Issues

1. **Startup fails with JWT binding error**:
   - Do not set `SECURITY_JWT_*` env vars — these are managed via `settings.yml` in `/configs`

2. **OCR Not Working**:
   ```bash
   docker exec stirling-pdf tesseract --list-langs
   ls -la /storage/data/stirling-pdf/tessdata/
   ```

3. **Memory Issues with Large Files**:
   ```bash
   docker stats stirling-pdf
   # Increase limit in docker-compose.yml deploy.resources.limits.memory
   ```

4. **File Upload Issues**:
   ```bash
   # Verify volume permissions
   sudo chown -R 1000:1000 /storage/data/stirling-pdf/
   ```

### Debug Commands
```bash
# View logs
docker compose logs -f stirling-pdf

# Check status
curl -f http://localhost:8080/api/v1/info/status

# Check available features
curl -X GET "https://pdf.alimunee.com/api/v1/info/endpoints"

# Monitor log file
docker exec stirling-pdf tail -f /logs/stirling-pdf.log
```

## Backup

The only data worth backing up is `/storage/data/stirling-pdf/config/` (settings, user DB, JWT keys). All other directories (tessdata, customFiles) are either stateless or can be re-downloaded.

```bash
# Backup config (user accounts, settings)
sudo tar -czf stirling-config-$(date +%Y%m%d).tar.gz -C /storage/data/stirling-pdf config/
```

## Security

- Login enabled with local user accounts (role-based, up to 5 users free)
- All PDF processing is fully local — no external API calls
- Running behind Traefik with HTTPS, no direct port exposure
- Temporary files auto-cleaned after processing
- API key authentication for programmatic access
