# IT-Tools

**Purpose**: Collection of handy online tools for developers and IT professionals

| Configuration Setting | Value                        |
| --------------------- | ---------------------------- |
| Image                 | `corentinth/it-tools:latest` |
| Memory Limits         | `512MB max, 64MB minimum`    |
| Timezone              | `Asia/Kuala_Lumpur`          |

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | tools.alimunee.com                          |
| TLS             | Disabled internally (handled by Cloudflare) |

**Network Settings**:

| Setting            | Value                |
| ------------------ | -------------------- |
| Web Interface Port | `80`                 |
| Domain             | `tools.alimunee.com` |
| Network            | `proxy`              |

**Security Considerations**:

- Stateless application with minimal security requirements
- Protected behind Traefik proxy
- No sensitive data stored

**Usage Instructions**:

1. Access the tools interface at tools.alimunee.com
2. Use any of the available developer and IT tools
3. No login or account creation required

**Available Tools**:

- Base64 encoder/decoder
- URL encoder/decoder
- JWT decoder
- Hash generators
- UUID generators
- Various converters and formatters
- Network tools
- And many more

**Maintenance**:

- Very low maintenance requirements
- Container updates for security patches
