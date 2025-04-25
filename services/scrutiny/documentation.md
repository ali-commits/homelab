# Scrutiny

**Purpose**: Hard Drive Health Dashboard & Monitoring solution

| Configuration Setting | Value                         |
| --------------------- | ----------------------------- |
| Image                 | `linuxserver/scrutiny:latest` |
| Memory Limits         | `1GB max, 128MB minimum`      |
| Timezone              | `Asia/Kuala_Lumpur`           |
| PUID/PGID             | `1000`                        |

**Configuration Details**:

| Configuration   | Details                                     |
| --------------- | ------------------------------------------- |
| External Access | disks.alimunee.com                          |
| API Endpoint    | http://localhost:8080                       |
| Web Interface   | Enabled                                     |
| Collector       | Enabled                                     |
| TLS             | Disabled internally (handled by Cloudflare) |

**Volume Mappings**:

| Volume        | Path                     |
| ------------- | ------------------------ |
| Configuration | `/storage/data/scrutiny` |
| udev          | `/run/udev` (read-only)  |
| Disk devices  | `/dev/disk`              |

**Device Mappings**:

- `/dev/sda`
- `/dev/sdb`
- `/dev/sdc`

**Network Settings**:

| Setting            | Value                |
| ------------------ | -------------------- |
| Web Interface Port | `8080`               |
| Domain             | `disks.alimunee.com` |
| Network            | `proxy`              |

**Capabilities**:

- SYS_RAWIO (required for SMART data access)

**Security Considerations**:

- Uses specific capabilities rather than privileged mode
- Runs as non-root user with PUID/PGID 1000
- Read-only access to udev for device detection

**Usage Instructions**:

1. Access the dashboard at disks.alimunee.com
2. View disk health status and SMART metrics
3. Configure alert thresholds if needed
4. Monitor historical disk performance trends

**Maintenance**:

- Check for collector errors in logs
- Update disk mappings if hardware changes
- Regularly verify that all disks are being monitored
