# AFFiNE

**Purpose**: Next-gen knowledge base with docs, whiteboards, and databases (Notion/Miro alternative)

| Configuration Setting | Value                                    |
| --------------------- | ---------------------------------------- |
| Image                 | `ghcr.io/toeverything/affine-self-hosted:latest` |
| Memory Limits         | `2GB max, 512MB minimum`                 |
| Timezone              | `Asia/Kuala_Lumpur`                      |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | notes.alimunee.com                    |
| TLS               | Disabled internally (handled by Cloudflare) |

**Volume Mappings**:

| Volume        | Path                    |
| ------------- | ----------------------- |
| Data          | `/storage/data/affine`  |

**Network Settings**:

| Setting            | Value                |
| ------------------ | -------------------- |
| Web Interface Port | `3000`               |
| Domain             | `notes.alimunee.com` |
| Network            | `proxy`              |

**Security Considerations**:

- Data is stored persistently in a dedicated volume
- Network isolation through Traefik proxy

**Usage Instructions**:

1. Access AFFiNE at notes.alimunee.com
2. Create workspaces for different projects
3. Use as a knowledge base, whiteboard, or document editor
4. All content is stored locally in your homelab

**Maintenance**:

- Regularly backup the data volume
- Check for updates to the container image
