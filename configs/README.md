# Homelab Configuration Management

This directory contains all configuration files for the homelab including system configurations, monitoring scripts, and deployment tools. It serves as a centralized location for all homelab configuration management.

## Directory Structure

```
/HOMELAB/configs/
├── system/                  # Core system configuration files
│   ├── fstab               # Filesystem mount table
│   ├── hostname            # System hostname configuration
│   ├── hosts               # Static host name resolution
│   └── notification-settings # System notification preferences
├── network/                # Network configuration files
│   └── interfaces          # Traditional network interface configuration (static IP)
├── security/               # Security-related configurations
│   ├── sshd_config         # SSH daemon configuration
│   ├── jail.local          # Fail2ban jail configuration (if present)
│   └── 50unattended-upgrades # Automatic security updates config (if present)
├── snapper/                # Btrfs snapshot configurations
│   ├── data                # Snapper config for /data
│   ├── immich              # Snapper config for immich volume
│   ├── root                # Snapper config for root filesystem
│   └── shared              # Snapper config for shared volume
├── nfs/                    # NFS server configurations
│   └── exports             # NFS export definitions
├── docker/                 # Docker daemon configurations
│   └── daemon.json         # Docker daemon configuration
├── scripts/                # Monitoring and maintenance scripts
│   ├── btrfs-smart-monitor.sh   # Main monitoring script
│   └── btrfs-scrub.sh           # Btrfs scrub script
├── systemd/                # Systemd service and timer files
│   ├── btrfs-smart-monitor.service
│   ├── btrfs-smart-monitor.timer
│   ├── btrfs-scrub.service
│   └── btrfs-scrub.timer
└── README.md              # This file
```

## Configuration Categories

### System Configuration (`system/`)
Core system files that define hostname, mount points, and basic system settings:
- **fstab**: Defines filesystem mount points and options
- **hostname**: System hostname configuration
- **hosts**: Static hostname to IP address mappings
- **notification-settings**: System notification preferences

### Network Configuration (`network/`)
Network interface and routing configurations:
- **interfaces**: Traditional network interface configuration with static IP (192.168.1.2/24)
  - Primary interface: enp2s0 with static IP configuration
  - Gateway: 192.168.1.1
  - DNS servers: 1.1.1.1, 8.8.8.8
- Support for Netplan YAML files (Ubuntu/Debian)
- Support for systemd-networkd configurations

### Security Configuration (`security/`)
Security-related service configurations:
- **sshd_config**: SSH daemon security settings
- **jail.local**: Fail2ban intrusion prevention rules
- **50unattended-upgrades**: Automatic security update settings

### Snapper Configuration (`snapper/`)
Btrfs snapshot management configurations for each volume:
- Individual configuration files for each Btrfs subvolume
- Defines snapshot frequency, retention, and cleanup policies

### NFS Configuration (`nfs/`)
Network File System server configuration:
- **exports**: Defines which directories are shared via NFS and access permissions

### Docker Configuration (`docker/`)
Docker daemon and runtime configurations:
- **daemon.json**: Docker daemon settings (logging, storage driver, etc.)

### Monitoring Scripts (`scripts/` & `systemd/`)
Automated monitoring and maintenance systems (see monitoring section below)

## New Monitoring Strategy

### Btrfs + SMART Monitoring

#### 1. Btrfs & SMART Monitor (`btrfs-smart-monitor.sh`)
**Frequency:** Every hour
**What it monitors:**
- ✅ Btrfs filesystem health and usage
- ✅ SMART status for all drives
- ✅ System resources (CPU, memory, disk space)
- ✅ Device error statistics
- ✅ Temperature monitoring

**Alerts sent for:**
- Storage space > 80% (warning) or > 90% (critical)
- SMART health failures
- Reallocated or pending sectors
- Drive temperature > 55°C (warning) or > 60°C (critical)
- High CPU/memory usage
- Btrfs device errors

#### 2. Btrfs Scrub (`btrfs-scrub.sh`)
**Frequency:** Weekly (randomized start time)
**What it does:**
- ✅ Data integrity verification
- ✅ Automatic error correction
- ✅ Reports corrected/uncorrectable errors

## System Overview

| Component | Specification | Purpose |
|-----------|---------------|---------|
| **OS** | Fedora 42 Server | Modern server platform |
| **CPU** | AMD Ryzen Threadripper 2920X (12-core/24-thread) | High-performance processing |
| **RAM** | 32GB DDR4 | Service hosting |
| **Storage** | 1TB NVMe + 3.6TB HDD | System + Data |
| **Network** | Static IP (192.168.1.2/24) | Homelab services |

## Current Configuration Status

### ✅ **COMPLETED (August 2025)**
- ✅ **Documentation updated**: All docs reflect new Fedora system
- ✅ **Hardware upgrade**: Threadripper + NVMe + more RAM
- ✅ **Monitoring scripts**: Updated for new hardware layout
- ✅ **Deployment script**: Created Fedora-specific deployment
- ✅ **Configuration files**: Updated UUIDs and interface names

### 🔄 **IN PROGRESS**
- ⏳ **Service migration**: Docker services being migrated
- ⏳ **Backup solution**: Evaluating alternatives to Restic
- ⏳ **Security hardening**: Adapting for Fedora/SELinux

### 📋 **PENDING**
- ⏸️ **Snapper setup**: Awaiting storage finalization
- ⏸️ **Performance tuning**: Post-migration optimization
- ⏸️ **Advanced monitoring**: Prometheus/Grafana integration

## Deployment and Usage

### Manual Configuration Deployment

All configurations should be deployed manually for better control and verification.

#### Core System Files
```bash
# Copy system files (requires root)
sudo cp /HOMELAB/configs/system/fstab /etc/fstab
sudo cp /HOMELAB/configs/system/hostname /etc/hostname
sudo cp /HOMELAB/configs/system/hosts /etc/hosts
sudo cp /HOMELAB/configs/system/notification-settings /etc/default/notification-settings

# Apply hostname change
sudo hostnamectl set-hostname $(cat /etc/hostname)

# Reload systemd for fstab changes
sudo systemctl daemon-reload
```

#### Security Configurations
```bash
# SSH configuration
sudo cp /HOMELAB/configs/security/sshd_config /etc/ssh/sshd_config
sudo systemctl restart sshd

# Fail2ban (if configured)
sudo cp /HOMELAB/configs/security/jail.local /etc/fail2ban/jail.local
sudo systemctl restart fail2ban

# Unattended upgrades (if configured)
sudo cp /HOMELAB/configs/security/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
```

#### Snapper Configurations
```bash
# Install snapper if not present
sudo apt update && sudo apt install snapper

# Copy snapper configurations
sudo mkdir -p /etc/snapper/configs
sudo cp /HOMELAB/configs/snapper/* /etc/snapper/configs/

# Enable snapper for each configuration
for config in $(ls /HOMELAB/configs/snapper/); do
    sudo snapper -c $config list
done
```

#### NFS Configuration
```bash
# Install NFS server if not present
sudo apt update && sudo apt install nfs-kernel-server

# Copy NFS exports
sudo cp /HOMELAB/configs/nfs/exports /etc/exports

# Reload NFS exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
```

#### Docker Configuration
```bash
# Copy Docker daemon configuration
sudo mkdir -p /etc/docker
sudo cp /HOMELAB/configs/docker/daemon.json /etc/docker/daemon.json

# Restart Docker to apply changes
sudo systemctl restart docker
```

### Backup Current Configurations
Before making changes, backup your current configurations:

```bash
# Create backup directory
mkdir -p ~/config-backup-$(date +%Y%m%d)

# Backup system files
sudo cp /etc/fstab ~/config-backup-$(date +%Y%m%d)/
sudo cp /etc/hostname ~/config-backup-$(date +%Y%m%d)/
sudo cp /etc/hosts ~/config-backup-$(date +%Y%m%d)/

# Backup security configs
sudo cp /etc/ssh/sshd_config ~/config-backup-$(date +%Y%m%d)/
sudo cp -r /etc/fail2ban/ ~/config-backup-$(date +%Y%m%d)/ 2>/dev/null || true

# Backup other configs as needed
sudo cp /etc/exports ~/config-backup-$(date +%Y%m%d)/ 2>/dev/null || true
sudo cp /etc/docker/daemon.json ~/config-backup-$(date +%Y%m%d)/ 2>/dev/null || true
```

### Network Configuration Deployment
The current configuration uses traditional network interfaces with static IP:

```bash
# Deploy network configuration
sudo cp /HOMELAB/configs/network/interfaces /etc/network/interfaces

# Restart networking (be careful - this may disconnect you!)
sudo systemctl restart networking
# OR (safer - only restart the specific interface)
sudo ifdown enp2s0 && sudo ifup enp2s0
```

**Current Network Configuration:**
- Interface: `enp2s0`
- Static IP: `192.168.1.2/24`
- Gateway: `192.168.1.1`
- DNS: `1.1.1.1`, `8.8.8.8`

#### Docker Daemon Template
If you need a basic Docker configuration, create `/HOMELAB/configs/docker/daemon.json`:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "data-root": "/var/lib/docker"
}
```

## Testing

### Test Monitoring
```bash
# Run monitoring manually
sudo /usr/local/bin/btrfs-smart-monitor.sh

# Check logs
journalctl -u btrfs-smart-monitor.service -f
```

### Test Scrub
```bash
# Run scrub manually (warning: can take hours)
sudo /usr/local/bin/btrfs-scrub.sh

# Check scrub status
sudo btrfs scrub status /
sudo btrfs scrub status /storage/media
```

### View Timer Status
```bash
systemctl list-timers btrfs-*
```

### Quick Verification
```bash
# Check timer status
systemctl list-timers btrfs-*

# View recent monitoring logs
sudo journalctl -u btrfs-smart-monitor.service --since "1 hour ago"

# Test notification (replace with your topic)
curl -d "Test message" http://localhost:8888/system-alerts

# Check system health manually
sudo /usr/local/bin/btrfs-smart-monitor.sh
```

## Notifications

Notifications are sent via:
- **ntfy**: Configure in `/etc/default/notification-settings`
- **Email**: Requires mail command configured

### Configuration File: `/etc/default/notification-settings`
```bash
NTFY_URL="http://homelab.local:8080"
NTFY_TOPIC="homelab-alerts"
ALERT_EMAIL="your-email@domain.com"
```

## Future Improvements

### RAID Conversion Options (All Reversible)

#### Current Options (2 drives)
```bash
# Convert to RAID0 (better performance, same risk)
sudo btrfs balance start -dconvert=raid0 /storage/media

# Revert from RAID0 back to single (if needed)
sudo btrfs balance start -dconvert=single /storage/media
```

#### When Adding 3rd Drive
```bash
# Add new drive
sudo btrfs device add /dev/sdX1 /storage/media

# Convert to RAID5 (1 drive fault tolerance)
sudo btrfs balance start -dconvert=raid5 /storage/media
```

#### When Adding 4th Drive
```bash
# Add new drive
sudo btrfs device add /dev/sdY1 /storage/media

# Convert to RAID6 (2 drive fault tolerance)
sudo btrfs balance start -dconvert=raid6 /storage/media
```

#### Monitor Conversions
```bash
# Check conversion progress
sudo btrfs balance status /storage/media

# Cancel conversion if needed (safe)
sudo btrfs balance cancel /storage/media
```

### Additional Monitoring
Consider adding:
- ✅ UPS monitoring
- ✅ Network monitoring
- ✅ Container health checks
- ✅ Certificate expiration monitoring

## Troubleshooting

### Common Issues
1. **High disk usage**: Check snapshot retention in `/etc/snapper/configs/`
2. **SMART errors**: Replace drive immediately
3. **Btrfs balance stuck**: Use `sudo btrfs balance cancel /path`
4. **Scrub running too long**: Check with `sudo btrfs scrub status /path`

### Log Locations
- Monitoring: `/var/log/btrfs-smart-monitor.log`
- Scrub: `/var/log/btrfs-scrub.log`
- Systemd: `journalctl -u btrfs-smart-monitor.service`
