# ChartDB

**Purpose**: Web-based database diagramming editor with AI features

| Configuration Setting | Value                            |
| --------------------- | -------------------------------- |
| Image                 | `ghcr.io/chartdb/chartdb:latest` |
| Memory Limits         | `512MB max, 128MB minimum`       |
| Timezone              | `Asia/Kuala_Lumpur`              |

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | dbdiagram.alimunee.com                      |
| OpenAI API Key  | Optional (for AI features)                  |
| TLS             | Disabled internally (handled by Cloudflare) |

**Volume Mappings**:

| Volume | Path                    |
| ------ | ----------------------- |
| Data   | `/storage/data/chartdb` |

**Network Settings**:

| Setting            | Value                    |
| ------------------ | ------------------------ |
| Web Interface Port | `3000`                   |
| Domain             | `dbdiagram.alimunee.com` |
| Network            | `proxy`                  |

**Security Considerations**:

- Protected behind Traefik proxy.
- OpenAI API key should be kept secret if used.
- Primarily a client-side tool, but ensure secure database connections.

**Usage Instructions**:

1. Access the interface at dbdiagram.alimunee.com.
2. Connect to your database (provide connection details).
3. Use the "Smart Query" feature to automatically generate a diagram.
4. Manually design or modify database relationship diagrams.
5. Use AI features (if API key is provided) to generate DDL scripts.
6. Export diagrams or SQL scripts.

**Features**:

- Database diagramming (ER diagrams).
- Automatic diagram generation from database connection ("Smart Query").
- AI-powered DDL script generation (requires OpenAI API key).
- Export diagrams and SQL scripts.

**Maintenance**:

- Low maintenance requirements.
- Update the container for security patches and new features.
