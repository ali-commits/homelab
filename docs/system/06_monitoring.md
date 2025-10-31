# System Monitoring

## Configuration Files Location
- **Scripts**: `/HOMELAB/configs/scripts/` → `/usr/local/bin/`
- **Services**: `/HOMELAB/configs/systemd/` → `/etc/systemd/system/`
- **Notifications**: `/HOMELAB/configs/system/notification-settings` → `/etc/default/notification-settings`

*For complete notification system documentation, see [Notification System](notifications.md)*

## Active Monitoring Services

| Service                   | Schedule   | Purpose                        | Status   |
| ------------------------- | ---------- | ------------------------------ | -------- |
| **Btrfs & SMART Monitor** | Hourly     | Real-time health monitoring    | ✅ Active |
| **Btrfs Scrub**           | Weekly     | Data integrity verification    | ✅ Active |
| **Snapper Snapshots**     | Hourly     | Automated filesystem snapshots | ✅ Active |
| **Fail2ban**              | Continuous | SSH intrusion detection        | ✅ Active |

### 1. Btrfs & SMART Monitor
- **Script**: `/usr/local/bin/btrfs-smart-monitor.sh`
- **Service**: `btrfs-smart-monitor.service`
- **Timer**: `btrfs-smart-monitor.timer` (every hour)
- **Log**: `/var/log/btrfs-smart-monitor.log`

#### Monitoring Targets
| Component        | Metrics                            | Thresholds                     |
| ---------------- | ---------------------------------- | ------------------------------ |
| **NVMe System**  | Usage %, health, temperature       | 80% warning, 90% critical      |
| **HDD Storage**  | Usage %, SMART status, temperature | 80% warning, 90% critical      |
| **SMART Health** | Drive health status                | Pass/Fail alerts               |
| **Temperature**  | Drive temperatures                 | 55°C warning, 60°C critical    |
| **CPU Load**     | System load average (24 threads)   | >20 load warning, >30 critical |
| **Memory**       | Memory usage % (32GB total)        | >90% usage alerts              |
| **Btrfs Errors** | Device statistics                  | Any errors trigger alert       |
| **GPU Status**   | NVIDIA driver, temperature         | Driver issues, >80°C warning   |

### 2. Btrfs Scrub Service
- **Script**: `/usr/local/bin/btrfs-scrub.sh`
- **Service**: `btrfs-scrub.service`
- **Timer**: `btrfs-scrub.timer` (weekly)
- **Log**: Journal (`journalctl -u btrfs-scrub`)

#### Scrub Coverage
| Filesystem      | Mount Point          | Device         | Purpose                 |
| --------------- | -------------------- | -------------- | ----------------------- |
| **NVMe System** | `/`                  | /dev/nvme0n1p2 | System files and Docker |
| **HDD Storage** | `/storage/media`     | /dev/sda1      | Media files             |
| **HDD Storage** | `/storage/Immich`    | /dev/sda1      | Photo storage           |
| **HDD Storage** | `/storage/nextcloud` | /dev/sda1      | Cloud storage           |
| **HDD Storage** | `/storage/shared`    | /dev/sda1      | Shared data             |

### 3. Snapshot Monitoring
- **Service**: Snapper timeline and cleanup
- **Schedule**: Hourly snapshots, daily cleanup
- **Coverage**: All 5 configured subvolumes
- **Status**: Integrated with monitoring dashboard

### 4. Security Monitoring
- **Service**: fail2ban with SSH protection
- **Jails**: sshd, sshd-ddos
- **Integration**: Firewalld rule management
- **Alerting**: Failed login attempts and bans

## Monitoring Dashboard Tools

### Web-Based Monitoring Services
| Service         | URL                    | Purpose                   | Status   |
| --------------- | ---------------------- | ------------------------- | -------- |
| **Uptime Kuma** | `uptime.alimunee.com`  | Service uptime monitoring | ✅ Active |
| **Dockge**      | `dockge.alimunee.com`  | Container management      | ✅ Active |
| **Komodo**      | `komodo.alimunee.com`  | Infrastructure management | ✅ Active |
| **Traefik**     | `traefik.alimunee.com` | Reverse proxy dashboard   | ✅ Active |

### Notification Services
| Service  | URL                         | Purpose            | Status   |
| -------- | --------------------------- | ------------------ | -------- |
| **ntfy** | `notification.alimunee.com` | Push notifications | ✅ Active |

### Available Scripts
| Script                     | Purpose                      | Location                                |
| -------------------------- | ---------------------------- | --------------------------------------- |
| **btrfs-smart-monitor.sh** | Storage and SMART monitoring | `/usr/local/bin/btrfs-smart-monitor.sh` |
| **btrfs-scrub.sh**         | Filesystem integrity check   | `/usr/local/bin/btrfs-scrub.sh`         |

### Quick Status Commands
```bash
# Run monitoring script manually
sudo /usr/local/bin/btrfs-smart-monitor.sh

# Check system health
df -h
sudo smartctl -H /dev/nvme0n1 /dev/sda

# Check all timers
systemctl list-timers | grep -E "(btrfs|snapper)"

# Check Docker services
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"

# Check fail2ban status
sudo fail2ban-client status
```

## Alert System Configuration

*For detailed notification setup and all available channels, see [Notification System](notifications.md)*

### Notification Topics Used by Monitoring
| Service           | Topic           | Priority | Description                 |
| ----------------- | --------------- | -------- | --------------------------- |
| **Btrfs Monitor** | `system-alerts` | 4-5      | Storage and SMART alerts    |
| **Backup System** | `system-alerts` | 2-5      | Backup status notifications |


### Alert Severity Levels
| Level          | Triggers                | Examples                           |
| -------------- | ----------------------- | ---------------------------------- |
| 🔴 **Critical** | System failure risk     | SMART failure, >90% storage, >60°C |
| 🟡 **Warning**  | Performance degradation | >80% storage, >55°C, high CPU      |
| 🔵 **Info**     | Normal operations       | Scrub completion, status updates   |

## Management Commands

### Service Control
```bash
# Check timer status
systemctl list-timers btrfs-*

# Start monitoring immediately
sudo systemctl start btrfs-smart-monitor.service

# Start scrub manually
sudo systemctl start btrfs-scrub.service

# View service status
systemctl status btrfs-smart-monitor.timer
systemctl status btrfs-scrub.timer
```

### Log Analysis
```bash
# View recent monitoring logs
sudo journalctl -u btrfs-smart-monitor.service --since "1 hour ago"

# View scrub logs
sudo journalctl -u btrfs-scrub.service --since "1 week ago"

# Check log files
sudo tail -f /var/log/btrfs-smart-monitor.log
sudo tail -f /var/log/btrfs-scrub.log
```

### Manual Health Checks
```bash
# Run monitoring script manually
sudo /usr/local/bin/btrfs-smart-monitor.sh

# Check filesystem usage
df -h

# Btrfs device status
sudo btrfs fi show

# SMART health check
sudo smartctl -H /dev/nvme0n1
sudo smartctl -H /dev/sda

# GPU monitoring
nvidia-smi
watch -n 1 nvidia-smi  # Real-time monitoring

# Check GPU in containers
docker exec jellyfin nvidia-smi
docker exec immich_machine_learning nvidia-smi
```

## Monitoring Dashboard

### Key Metrics to Monitor
| Metric           | Command                                                        | Normal Range           |
| ---------------- | -------------------------------------------------------------- | ---------------------- |
| **Disk Usage**   | `df -h`                                                        | < 80%                  |
| **SMART Health** | `smartctl -H /dev/sdX`                                         | PASSED                 |
| **Temperature**  | `smartctl -A /dev/sdX \| grep Temp`                            | < 55°C                 |
| **Btrfs Errors** | `sudo btrfs dev stats /`                                       | 0 errors               |
| **Memory**       | `free -h`                                                      | < 80% used (32GB)      |
| **CPU Load**     | `uptime`                                                       | < 20 load (24 threads) |
| **GPU Status**   | `nvidia-smi`                                                   | Driver OK, < 80°C      |
| **GPU Memory**   | `nvidia-smi --query-gpu=memory.used,memory.total --format=csv` | < 6GB used (8GB)       |

## Troubleshooting

### Common Issues
| Problem                | Diagnosis            | Solution                        |
| ---------------------- | -------------------- | ------------------------------- |
| **No alerts received** | Check ntfy service   | `sudo systemctl status ntfy`    |
| **Timer not running**  | Check systemd timers | `systemctl list-timers btrfs-*` |
| **High disk usage**    | Check large files    | `sudo du -sh /*`                |
| **SMART warnings**     | Check drive health   | `sudo smartctl -a /dev/sdX`     |

### Emergency Procedures
```bash
# Stop monitoring (if causing issues)
sudo systemctl stop btrfs-smart-monitor.timer

# Check system load
top

# Check disk I/O
sudo iotop

# Emergency storage cleanup
sudo apt autoremove && sudo apt autoclean
```

## Configuration Management

### Configuration Files
All monitoring configs are managed in `/HOMELAB/configs/`:
- Scripts: `configs/scripts/`
- Systemd units: `configs/systemd/`
- Deployment: `configs/deploy-configs.sh`

### Settings
Notification settings: `/etc/default/notification-settings`
```bash
NTFY_URL="http://homelab.local:8080"
NTFY_TOPIC="homelab-alerts"
ALERT_EMAIL="your-email@domain.com"
```

## Manual Monitoring Commands

### Storage Health
```bash
# Comprehensive storage check
sudo btrfs fi show
sudo btrfs fi usage /
sudo btrfs fi usage /storage/media

# Drive health
sudo smartctl -a /dev/nvme0n1 | grep -E "(Health|Temperature|Critical)"
sudo smartctl -a /dev/sda | grep -E "(Health|Reallocated|Pending|Temperature)"
```

### System Resources
```bash
# Resource usage
htop
iostat -x 1
free -h

# Drive temperatures
sudo smartctl -A /dev/sda | grep Temperature
```

### Maintenance
```bash
# Manual scrub (can take hours)
sudo btrfs scrub start /
sudo btrfs scrub start /storage/media
sudo btrfs scrub status /

# Balance filesystem (if needed)
sudo btrfs balance start /storage/media
```

## Future Improvements

### Planned Enhancements
1. **Advanced Metrics**: Prometheus/Grafana for historical data
2. **Container Monitoring**: Docker health checks integration

## Future Improvements

### Planned Enhancements
| Enhancement              | Priority | Description                                      |
| ------------------------ | -------- | ------------------------------------------------ |
| **Grafana Dashboard**    | Medium   | Historical metrics visualization                 |
| **Container Monitoring** | Medium   | Docker health checks integration                 |
| **Network Monitoring**   | Low      | Bandwidth and latency tracking                   |
| **UPS Integration**      | Low      | Power monitoring and graceful shutdown           |

### Modern Monitoring Stack
| Component                | Technology     | Purpose                       |
| ------------------------ | -------------- | ----------------------------- |
| **Service Monitoring**   | Uptime Kuma    | Web service availability      |
| **Container Management** | Dockge         | Docker service monitoring     |
| **Infrastructure**       | Komodo         | Server and service management |
| **Notifications**        | ntfy           | Alert delivery system         |
| **Storage Health**       | Custom scripts | Btrfs and SMART monitoring    |

---
*For detailed configuration files, see: `/HOMELAB/configs/scripts/` and `/HOMELAB/configs/systemd/`*
