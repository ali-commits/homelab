# Stirling-PDF

**Purpose**: Self-hosted web-based PDF manipulation tool

| Configuration Setting | Value                    |
| --------------------- | ------------------------ |
| Image                 | `frooodle/s-pdf:latest`  |
| Memory Limits         | `1GB max, 256MB minimum` |
| Timezone              | `Asia/Kuala_Lumpur`      |
| PUID/PGID             | `1000`                   |

**Configuration Details**:

| Configuration     | Details                                     |
| ----------------- | ------------------------------------------- |
| External Access   | pdf.alimunee.com                            |
| Security          | Disabled (internal use only)                |
| PDF Save Location | /app/storage                                |
| TLS               | Disabled internally (handled by Cloudflare) |

**Volume Mappings**:

| Volume        | Path                                 |
| ------------- | ------------------------------------ |
| Configuration | `/storage/data/stirling-pdf/config`  |
| Storage       | `/storage/data/stirling-pdf/storage` |

**Network Settings**:

| Setting            | Value              |
| ------------------ | ------------------ |
| Web Interface Port | `8080`             |
| Domain             | `pdf.alimunee.com` |
| Network            | `proxy`            |

**Security Considerations**:

- Authentication is disabled by default for internal use only
- Protected by Traefik reverse proxy
- Runs as non-root user with PUID/PGID 1000
- No outbound calls per developer design

**Usage Instructions**:

1. Access the interface at pdf.alimunee.com
2. Upload PDF files for manipulation
3. Use any of the available operations:
   - Split PDFs
   - Merge multiple PDFs
   - Convert to/from different formats
   - Add images
   - Rotate pages
   - Compress PDFs
   - Clean up scanned documents
   - OCR (text recognition)
4. Download the processed files

**Maintenance**:

- Periodically clean up the storage volume if needed
- Update the container for security patches and new features
