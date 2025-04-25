# n8n

**Purpose**: Workflow automation platform with visual building and AI capabilities

| Configuration Setting | Value                    |
| --------------------- | ------------------------ |
| Image                 | `n8nio/n8n:latest`       |
| Database              | `SQLite` (default)       |
| Memory Limits         | `2GB max, 512MB minimum` |
| Timezone              | `Asia/Kuala_Lumpur`      |
| PUID/PGID             | `1000`                   |

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | automate.alimunee.com                       |
| Basic Auth      | Disabled                                    |
| Protocol        | HTTPS                                       |
| Webhook URL     | https://automate.alimunee.com/              |
| TLS             | Disabled internally (handled by Cloudflare) |

**Volume Mappings**:

| Volume | Path                |
| ------ | ------------------- |
| Data   | `/storage/data/n8n` |

**Network Settings**:

| Setting            | Value                   |
| ------------------ | ----------------------- |
| Web Interface Port | `5678`                  |
| Domain             | `automate.alimunee.com` |
| Network            | `proxy`                 |

**Security Considerations**:

- Basic authentication is disabled; relies on reverse proxy or future SSO for access control.
- Protected behind Traefik proxy.
- Runs as non-root user with PUID/PGID 1000.
- Credentials for integrated services should be managed securely within n8n.

**Usage Instructions**:

1. Access the n8n interface at automate.alimunee.com.
2. Create your first user account.
3. Start building workflows using the visual editor.
4. Connect to various services (400+ integrations available).
5. Utilize built-in AI capabilities for smarter workflows.
6. Trigger workflows manually, on a schedule, or via webhooks.

**Features**:

- Visual workflow builder.
- Integration with over 400 services.
- Custom code nodes (JavaScript).
- Native AI capabilities.
- Trigger nodes (schedule, webhook, manual).
- Error handling and logging.

**Maintenance**:

- Regularly backup the data volume (contains workflows and credentials).
- Update the container for security patches and new features/integrations.
- Monitor workflow execution logs for errors.
