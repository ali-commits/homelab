# ConvertX

**Purpose**: Self-hosted online file converter supporting over 1000 formats

| Configuration Setting | Value                         |
| --------------------- | ----------------------------- |
| Image                 | `ghcr.io/c4illin/convertx:latest` |
| Memory Limits         | `1GB max, 256MB minimum`      |
| Timezone              | `Asia/Kuala_Lumpur`           |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | convert.alimunee.com                  |
| TLS               | Disabled internally (handled by Cloudflare) |

**Volume Mappings**:

| Volume        | Path                    |
| ------------- | ----------------------- |
| Data          | `/storage/data/convertx` |

**Network Settings**:

| Setting            | Value                  |
| ------------------ | ---------------------- |
| Web Interface Port | `3000`                 |
| Domain             | `convert.alimunee.com` |
| Network            | `proxy`                |

**Security Considerations**:
- No authentication system - relies on reverse proxy for access control
- Protected behind Traefik proxy
- Isolated network access

**Usage Instructions**:
1. Access the interface at convert.alimunee.com
2. Upload the file you want to convert
3. Select the desired output format
4. Download the converted file

**Maintenance**:
- Periodically clean up the data volume to free up space
- Keep the container updated for security patches and new features
