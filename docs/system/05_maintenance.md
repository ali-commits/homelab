# System Maintenance

## Configuration Files Location
- **Maintenance Scripts**: `/HOMELAB/configs/scripts/` → `/usr/local/bin/`
- **Systemd Services**: `/HOMELAB/configs/systemd/` → `/etc/systemd/system/`

## Automated Maintenance Schedule

| Task                    | Frequency | Purpose           | Implementation              |
| ----------------------- | --------- | ----------------- | --------------------------- |
| **SMART/Btrfs Monitor** | Hourly    | Health monitoring | `btrfs-smart-monitor.timer` |
| **Btrfs Scrub**         | Weekly    | Data integrity    | `btrfs-scrub.timer`         |
| **Snapshot Cleanup**    | Automatic | Space management  | Snapper timeline cleanup    |
| **Security Updates**    | Daily     | System security   | Unattended upgrades         |

## Manual Maintenance Tasks

### Daily Tasks
- **Automated**: SMART status checks
- **Automated**: System monitoring alerts
- **Automated**: Snapshot creation/cleanup
- **Automated**: Security updates

### Weekly Tasks
- **Automated**: Btrfs scrub operations
- **Manual**: Docker cleanup
- **Manual**: Package cleanup
- **Manual**: Log review

### Monthly Tasks
- **Manual**: Performance review
- **Manual**: Security audit
- **Manual**: Storage optimization
- **Manual**: Backup verification

## Maintenance Commands

### System Health Checks
```bash
# Overall system status
sudo /usr/local/bin/btrfs-smart-monitor.sh

# Filesystem usage
sudo btrfs filesystem usage /
sudo btrfs filesystem usage /storage/media

# Check all timers
systemctl list-timers --all

# Storage health
df -h
sudo smartctl -H /dev/nvme0n1
sudo smartctl -H /dev/sda
```

### Btrfs Maintenance
```bash
# Manual scrub (can take hours)
sudo btrfs scrub start /
sudo btrfs scrub start /storage/Immich
sudo btrfs scrub start /storage/nextcloud
sudo btrfs scrub start /storage/media

# Check scrub status
sudo btrfs scrub status /

# Manual balance (if needed)
sudo btrfs balance start -dusage=50 /storage/media

# Filesystem defragmentation
sudo btrfs filesystem defragment -r /home
```

### Security Maintenance
```bash
# Check fail2ban status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# SSH security audit
sudo journalctl -u sshd --since "1 day ago" | grep -E "(Failed|Accepted)"

# Update system manually (Fedora)
sudo dnf update && sudo dnf upgrade
```

### Docker Maintenance
```bash
# Clean up Docker resources
docker system prune -f

# Remove unused volumes
docker volume prune -f

# Remove unused images
docker image prune -a -f

# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"

# Check resource usage
docker stats --no-stream

# Update containers (Watchtower handles this automatically)
# Manual update if needed:
# cd /HOMELAB/services && find . -name "docker-compose.yml" -execdir docker-compose pull \;
```

## Performance Optimization

### Storage Optimization
| Task                   | Command                                      | Frequency |
| ---------------------- | -------------------------------------------- | --------- |
| **TRIM SSD**           | `sudo fstrim -av`                            | Weekly    |
| **Compress old files** | `sudo btrfs filesystem defragment -czstd`    | Monthly   |
| **Balance metadata**   | `sudo btrfs balance start -mfilter=usage=50` | As needed |

### Memory/CPU Optimization
```bash
# Check system resources
htop
iostat -x 1 5

# Clear system caches (if needed)
sudo sync && sudo sysctl vm.drop_caches=3

# Check high resource processes
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10
```

## Troubleshooting Common Issues

### Storage Issues
| Problem             | Diagnosis                | Solution                              |
| ------------------- | ------------------------ | ------------------------------------- |
| **High disk usage** | `dust -sh /*`              | Clean logs, Docker cleanup            |
| **Btrfs errors**    | `sudo btrfs dev stats /` | Run scrub, check hardware             |
| **Slow I/O**        | `sudo iotop`             | Check disk health, balance filesystem |

### Service Issues
| Problem               | Diagnosis                    | Solution                          |
| --------------------- | ---------------------------- | --------------------------------- |
| **Timer not running** | `systemctl list-timers`      | Enable/restart timer              |
| **Service failed**    | `journalctl -u service-name` | Check logs, fix configuration     |
| **High load**         | `uptime`                     | Identify resource-heavy processes |

### Emergency Procedures
```bash
# Stop all non-essential services
sudo systemctl stop docker
sudo systemctl stop nextcloud-aio-*

# Emergency storage cleanup
sudo dnf autoremove && sudo dnf clean all
sudo journalctl --vacuum-time=7d

# Force filesystem check (if unmountable)
sudo btrfs check --readonly /dev/device
```

## Maintenance Checklist

### Weekly Checklist
- [ ] Review monitoring alerts
- [ ] Check service status: `systemctl --failed`
- [ ] Verify backup integrity
- [ ] Review disk usage: `df -h`
- [ ] Check security logs
- [ ] Update documentation if needed

### Monthly Checklist
- [ ] Review system performance
- [ ] Update system packages
- [ ] Security audit (SSH logs, fail2ban)
- [ ] Capacity planning review
- [ ] Test disaster recovery procedures
- [ ] Review and update documentation

---
*For automated monitoring details, see: [System Monitoring](monitoring.md)*
