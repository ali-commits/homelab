# Dozzle

**Purpose**: Lightweight, web-based, real-time log viewer for Docker containers

| Configuration Setting | Value                     |
| --------------------- | ------------------------- |
| Image                 | `amir20/dozzle:latest`    |
| Memory Limits         | `256MB max, 64MB minimum` |
| Timezone              | `Asia/Kuala_Lumpur`       |

**Configuration Details**:

| Configuration     | Details                               |
|-------------------|---------------------------------------|
| External Access   | logs.alimunee.com                     |
| Log Level         | Info                                  |
| Tail Size         | 300 lines                             |
| Container Filter  | Only running containers               |
| TLS               | Disabled internally (handled by Cloudflare) |

**Volume Mappings**:

| Volume        | Path                           |
| ------------- | ------------------------------ |
| Docker Socket | `/var/run/docker.sock` (read-only) |

**Network Settings**:

| Setting            | Value                |
| ------------------ | -------------------- |
| Web Interface Port | `8080`               |
| Domain             | `logs.alimunee.com`  |
| Network            | `proxy`              |

**Security Considerations**:
- Read-only access to Docker socket
- Protected behind Traefik proxy
- Low memory footprint
- No authentication by default (relies on reverse proxy protection)

**Usage Instructions**:
1. Access the interface at logs.alimunee.com
2. View real-time logs from all running Docker containers
3. Filter logs by container or content
4. Search for specific text in logs
5. Analyze JSON logs with color coding
6. Use SQL queries for advanced log analysis (via WebAssembly and DuckDB)

**Maintenance**:
- Very low maintenance requirements
- Update the container for security patches and new features
