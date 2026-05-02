# Storage Configuration

## 📁 Configuration Files Location
- **Filesystem Table**: `/HOMELAB/configs/system/fstab` → `/etc/fstab`
- **Snapper Configs**: `/HOMELAB/configs/snapper/` → `/etc/snapper/configs/`

## 💾 Storage Architecture Overview

The homelab uses a multi-tier Btrfs storage architecture providing flexibility, snapshots, and data protection.

| Tier        | Device(s)          | Capacity | Purpose                   | RAID Level |
| ----------- | ------------------ | -------- | ------------------------- | ---------- |
| **System**  | NVMe SSD (nvme0n1) | 1TB      | OS, applications, Docker  | Single     |
| **Storage** | Single HDD (sda)   | 3.6TB    | Media, photos, cloud data | Single     |

## 🏗️ Current Storage Layout

### System Storage (NVMe)
| Partition | Device           | Size  | Mount Point | Filesystem | Label  |
| --------- | ---------------- | ----- | ----------- | ---------- | ------ |
| **EFI**   | `/dev/nvme0n1p1` | 512MB | `/boot/efi` | FAT32      | -      |
| **Root**  | `/dev/nvme0n1p2` | 953GB | `/`         | Btrfs      | system |

### Data Storage (Single HDD)
| Device    | Size  | Role              | Filesystem    | Label   |
| --------- | ----- | ----------------- | ------------- | ------- |
| **sda1**  | 3.6TB | Data storage      | Btrfs         | storage |
| **Total** | 3.6TB | Available storage | Single device |

## 📊 Btrfs Configuration Details

### Root Filesystem (`/dev/nvme0n1p2`)
- **Label**: "system"
- **UUID**: `cfe8****************************2a7a`
- **Profile**: Single device
- **Compression**: zstd (default)
- **Usage**: ~50GB used / 953GB total

### Storage Filesystem (`/dev/sda1`)
- **Label**: "storage"
- **UUID**: `b57a*****************************47e`
- **Data Profile**: Single device
- **Metadata Profile**: Single device
- **Compression**: zstd (default)
- **Usage**: ~900GB used / 3.6TB total

## 📁 Subvolume Layout

### System Subvolumes (`/`)
| Subvolume | Mount Point | Purpose         | Snapshots     |
| --------- | ----------- | --------------- | ------------- |
| `@`       | `/`         | Root filesystem | Yes (Snapper) |

### Storage Subvolumes
| Subvolume         | Mount Point          | Purpose          | Device | Snapshots     |
| ----------------- | -------------------- | ---------------- | ------ | ------------- |
| `@`               | `/`                  | Root filesystem  | NVMe   | Yes (Snapper) |
| `@data`           | `/storage/data`      | Application data | NVMe   | Yes (Snapper) |
| `@tmp`            | `/tmp`               | Temporary files  | NVMe   | No            |
| `@var`            | `/var`               | Variable data    | NVMe   | No            |
| `@var_cache`      | `/var/cache`         | System cache     | NVMe   | No            |
| `@var_logs`       | `/var/logs`          | System logs      | NVMe   | No            |
| `@var_lib_docker` | `/var/lib/docker`    | Docker data      | NVMe   | No            |
| `@media`          | `/storage/media`     | Media files      | HDD    | Manual        |
| `@immich`         | `/storage/Immich`    | Photo library    | HDD    | Yes (Snapper) |
| `@shared`         | `/storage/shared`    | Shared data      | HDD    | Yes (Snapper) |

**Mount Options**: `noatime,compress=zstd,space_cache=v2,subvol=@`

**Mount Options**: `noatime,compress=zstd,space_cache=v2,subvol=@subvolume`

**Current Configuration**:
- **Data**: Single device profile (no redundancy)
- **Metadata**: Single device profile (no redundancy)
- **Available Space**: ~2.8TB free of 3.6TB total

## 🚀 Storage Management Commands

### Filesystem Health Checks
```bash
# Check overall filesystem status
sudo btrfs filesystem show
sudo btrfs filesystem usage /
sudo btrfs filesystem usage /storage/media

# Monitor device health and errors
sudo btrfs device stats /
sudo btrfs device stats /storage/media

# Check space usage by subvolume
sudo btrfs subvolume list /
sudo btrfs subvolume show /storage/Immich
```

### RAID Management
```bash
# Check RAID status
sudo btrfs filesystem show /storage/media

# Balance filesystem (redistribute data)
sudo btrfs balance start -dusage=50 /storage/media

# Add new device to RAID (future expansion)
# sudo btrfs device add /dev/sdX /storage/media

# Remove device from RAID
# sudo btrfs device remove /dev/sdX /storage/media
```

### Snapshot Operations
```bash
# Manual snapshot creation
sudo snapper -c root create --description "Before system update"
sudo snapper -c immich create --description "Before upgrade"

# List snapshots
sudo snapper -c root list
sudo snapper -c immich list

# Cleanup old snapshots
sudo snapper -c root cleanup number
sudo snapper cleanup
```

## 📊 Storage Performance & Monitoring

### Performance Characteristics
| Metric          | System Storage (NVMe) | Data Storage (HDD)       |
| --------------- | --------------------- | ------------------------ |
| **Capacity**    | 953GB                 | 3.6TB                    |
| **Read Speed**  | ~3500 MB/s            | ~150 MB/s                |
| **Write Speed** | ~3000 MB/s            | ~120 MB/s                |
| **IOPS**        | Very High (NVMe)      | Moderate (spinning disk) |
| **Compression** | zstd                  | zstd                     |

### Monitoring Integration
- ✅ **Automated**: Btrfs scrub weekly
- ✅ **Automated**: SMART monitoring hourly
- ✅ **Automated**: Space usage alerts (80%/90%)
- ✅ **Automated**: Error detection and notification

## 🔧 Maintenance & Optimization

### Regular Maintenance Tasks
| Task                 | Frequency | Purpose                     |
| -------------------- | --------- | --------------------------- |
| **Scrub**            | Weekly    | Data integrity verification |
| **Balance**          | Monthly   | Optimize space allocation   |
| **Snapshot cleanup** | Daily     | Automatic via Snapper       |
| **SMART checks**     | Hourly    | Drive health monitoring     |

### Storage Optimization Tips
```bash
# Defragment files (for better compression)
sudo btrfs filesystem defragment -r -v /home

# Check compression ratio
sudo compsize /storage/Immich

# Find large files
sudo du -sh /storage/* | sort -hr
```

## ⚠️ Important Notes

### Data Protection Status
| Component       | Protection Level | Risk                                   |
| --------------- | ---------------- | -------------------------------------- |
| **System data** | Single NVMe      | Hardware failure = data loss           |
| **User data**   | Single HDD       | Hardware failure = data loss           |
| **Snapshots**   | Local only       | Not protected against hardware failure |
| **Backups**     | External S3      | Protected against hardware failure     |

### Backup Recommendations
- 🔴 **Critical**: Regular external backups required. See [backups.md](./backups.md) for the off-site S3 backup strategy.
- 🔴 **Important**: Test restore procedures regularly
- 🟡 **Note**: Snapshots protect against user error, not hardware failure
- 🟡 **Future**: Consider RAID1 for critical data when drives available

---
*For filesystem mount configuration, see: `/HOMELAB/configs/system/fstab`*
---
*For filesystem mount configuration, see: `/HOMELAB/configs/system/fstab`*
*For snapshot policies, see: `/HOMELAB/configs/snapper/`*
*For NFS exports, see: `/HOMELAB/configs/nfs/exports`*
