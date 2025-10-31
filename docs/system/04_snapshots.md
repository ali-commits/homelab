# Snapper Configuration

The system uses Snapper for managing Btrfs snapshots with different configurations for various subvolumes.

## Configuration Files Location
- **Source**: `/HOMELAB/configs/snapper/`
- **System Location**: `/etc/snapper/configs/`

## Snapshot Strategy

The homelab uses Snapper for local snapshot management:

**Local Snapshots (Snapper)**: Provides instant, frequent, on-site snapshots for rapid recovery from common issues like accidental file deletion, configuration errors, or bad software updates. These are not true backups as they reside on the same physical hardware.

**Note**: The previous backup service to S3 has been deprecated. Future backup solutions will be implemented separately.

## Snapshot Configurations Overview

| Subvolume            | Hourly | Daily | Weekly | Monthly | Space Limit | Free Limit |
| -------------------- | ------ | ----- | ------ | ------- | ----------- | ---------- |
| `/` (root)           | 5      | 7     | 4      | 2       | 20%         | 20%        |
| `/storage/data`      | 5      | 7     | 4      | 2       | 25%         | 20%        |
| `/storage/nextcloud` | 5      | 7     | 4      | 2       | 25%         | 20%        |
| `/storage/Immich`    | 5      | 7     | 4      | 2       | 25%         | 20%        |
| `/storage/shared`    | 5      | 7     | 4      | 2       | 25%         | 20%        |

## Configuration Details

### Root Filesystem (`/`)
- **Config File**: `/HOMELAB/configs/snapper/root`
- **Key Settings**:
  - Timeline snapshots: Enabled
  - Minimum age: 30 minutes (1800 seconds)
  - Conservative space usage (20% limits)
  - Automatic cleanup enabled

### Data Volumes (nextcloud, immich, data, shared)
- **Config Files**:
  - `/HOMELAB/configs/snapper/nextcloud`
  - `/HOMELAB/configs/snapper/immich`
  - `/HOMELAB/configs/snapper/data`
  - `/HOMELAB/configs/snapper/shared`
- **Key Settings**:
  - Higher space limits (25%) for data safety
  - Same retention schedule as root
  - Background comparison enabled
  - ACL synchronization enabled

## Management Commands

### View Snapshots
```bash
# List all configurations
sudo snapper list-configs

# List snapshots for specific config
sudo snapper -c root list
sudo snapper -c nextcloud list
sudo snapper -c immich list
```

### Manual Snapshots
```bash
# Create manual snapshot
sudo snapper -c root create --description "Before system update"
sudo snapper -c nextcloud create --description "Before app update"
```

### Cleanup
```bash
# Manual cleanup
sudo snapper -c root cleanup number
sudo snapper -c nextcloud cleanup timeline
```

## Common Settings for All Configs
- ✅ Timeline creation enabled
- ✅ Timeline cleanup enabled
- ✅ Background comparison enabled
- ✅ ACL synchronization enabled
- ✅ Number-based cleanup (10 snapshot limit)
- ✅ Empty pre/post snapshot scripts
