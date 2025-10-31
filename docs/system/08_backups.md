# Off-site S3 Backups

This document details the off-site backup strategy for the homelab, which uses Kopia to provide disaster recovery protection with deduplication, encryption, and automatic S3 Glacier archiving.

## Configuration Files

| File Type               | Location                                                                                   | Deployed To                                |
| ----------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------ |
| **Backup Script**       | [`./configs/scripts/kopia-backup.sh`](../../configs/scripts/kopia-backup.sh)               | `/usr/local/bin/kopia-backup.sh`           |
| **Systemd Service**     | [`./configs/systemd/kopia-backup.service`](../../configs/systemd/kopia-backup.service)     | `/etc/systemd/system/kopia-backup.service` |
| **Systemd Timer**       | [`./configs/systemd/kopia-backup.timer`](../../configs/systemd/kopia-backup.timer)         | `/etc/systemd/system/kopia-backup.timer`   |
| **Environment Config**  | [`./configs/defaults/kopia-backup.env`](../../configs/defaults/kopia-backup.env)           | `/etc/default/kopia-backup`                |
| **Notification Config** | [`./configs/defaults/notification-settings`](../../configs/defaults/notification-settings) | `/etc/default/notification-settings`       |

## Backup Strategy

The backup system follows the **3-2-1 rule** by creating an off-site, encrypted, deduplicated copy of critical subvolumes.

- **Technology**: Kopia provides block-level deduplication, compression, and encryption
- **Storage**: AWS S3 with automatic Glacier transition after 24 hours for cost optimization
- **Encryption**: AES256-GCM-HMAC-SHA256 client-side encryption with repository password
- **Deduplication**: Content-defined chunking with BLAKE2B-256-128 hashing
- **Compression**: zstd-fastest compression for metadata
- **Incremental Backups**: Only changed blocks are uploaded, saving bandwidth and storage
- **Retention**: 10 daily snapshots + 12 monthly snapshots (automatic cleanup)
- **Exclusions**: Automatically excludes `.snapshots/` directories (Btrfs snapshots)
- **Verification**: Built-in integrity checking and error detection
- **Logging**: All actions logged to `/var/log/kopia-backup.log`
- **Notifications**: Success/failure notifications via ntfy to `homelab-alerts` topic

## Configuration

### Repository Settings
- **Storage**: S3 bucket `myhomelab-backups` in `us-east-1`
- **Format**: Kopia format version 3 with content compression
- **Splitter**: DYNAMIC-4M-BUZHASH for optimal deduplication
- **Max Pack Length**: 21 MB for efficient S3 uploads

### Backup Targets

| Subvolume            | Status   | Typical Size | Description                                 |
| -------------------- | -------- | ------------ | ------------------------------------------- |
| `/storage/data`      | ✅ Active | ~10 GB       | Docker service configurations and databases |
| `/storage/Immich`    | ✅ Active | ~131 GB      | Photo and video library                     |
| `/storage/nextcloud` | ✅ Active | ~360 MB      | Nextcloud data and files                    |

### S3 Lifecycle Policy
```json
{
  "Rules": [
    {
      "ID": "KopiaBackupGlacierTransition",
      "Status": "Enabled",
      "Filter": { "Prefix": "" },
      "Transitions": [
        {
          "Days": 1,
          "StorageClass": "GLACIER"
        }
      ]
    }
  ]
}
```

## Management Commands

### Manual Backups
```bash
# Run backup for all configured subvolumes
sudo /usr/local/bin/kopia-backup.sh

# Check repository status
sudo kopia repository status

# List all snapshots
sudo kopia snapshot list

# Showtory statistics
sudo kopia content stats
```

### Monitoring
```bash
# View live backup logs
tail -f /var/log/kopia-backup.log

# Check systemd service status
systemctl status kopia-backup.service

# View recent service logs
journalctl -u kopia-backup.service --since "1 day ago"

# Check backup
sudo kopia policy show --global
```

### Repository Management
```bash
# Run maintenance manually
kopia maintenance run --full

# Check repository integrity
sudo kopia repositoryprovider

# Show cache statistics
sudo kopia cache info

# Clear cache if needed
sudo kopia cache clear
```

## Restore Procedure

Kopia provides flexible restore options from any snapshot.

### Step 1: List Available Snapshots
```bash
# List all snapshots
sudo kopia snapshot list

# List snapshots for specific path
sudo kopia snapshot list /storage/data

# Show snapshot details
sudo kopia snapshot showapshot-id>
```

### Step 2: Restore Options

#### Full Directory Restore
```bash
# Restore entire directoryocation
sudo kopia snapshot restore <snapshot-id> /tmp/restored-data

# Restore to original location (be careful!)
sudoapshot restore <snapshot-id> /storage/data-restored
```

#### Selective File Restore
```bash
# Mount snapshot as filesystem (read-only)
sudo mkdir /mnt/kopia-snapshot
sudo kopia mount <snapshot-id> /mnt/kopia-snapshot

# Copy specific files
cp /mnt/kopia-snapshot/path/to/file /desired/location

# Unmount when done
sudo umount /mnt/kopia-snapshot
```

#### Browse and Restore via Web UI
```bash
# Start Kopia server (optional)
sudo kopia server start --address=0.0.0.0:51515

# Access web UI at http://homelab.local:51515
# Browse snapshots and restore files through web interface
```

### Step 3: Verify and Replace
After restoration, verify the data integrity before replacing original files.

```bash
# Compare restored data
diff -r /storage/data /tmp/restored-data

# Replace original (if confident)
sudo mv /storage/data /storage/data.backup
sudo mv /tmp/restored-data /storage/data
```

## Scheduling

Backups are automated via systemd timer running daily at 2:00 AM.

- **Service**: `kopia-backup.service`
- **Timer**: `kopia-backup.timer`
- **Schedule**: Daily with 30-minute randomized delay

### Timer Management
```bash
# Check timer status
systemctl list-timers kopia-backup.timer

# Enable/disable timer
sudo systemctl enable kopia-backup.timer
sudo systemctl disable kopia-backup.timer

# Start/stop timer
sudo systemctl start kopia-backup.timer
sudo systemctl stop kopia-backup.timer

# Check last run status
systemctl status kopia-backup.service
```

## Troubleshooting

### Common Issues

#### Repository Connection Errors
**Problem**: Cannot connect to S3 repository
**Cause**: AWS credentials or network issues
**Solution**:
```bash
# Test AWS credentials
aws s3 ls s3://myhomelab-backups

# Check Kopia repository
sudo kopia repository status

# Reconnect if needed
sudo kopia repository connect s3 --bucket=myhomelab-backups
```

#### Permission Errors During Backup
**Problem**: Cannot read certain files (databases, system files)
**Cause**: Normal behavior - some files are locked or have restricted permissions
**Solution**: These errors are expected and logged. Critical data is still backed up.

#### Maintenance User Errors
**Problem**: "maintenance must be run by designated user"
**Cause**: Maintenance must run as the original repository user
**Solution**: Script automatically runs maintenance as correct user with `sudo -u ali`

#### Large Backup Times
**Problem**: Immich backup takes very long
**Cause**: Large photo/video files require time to process
**Solution**: This is normal. Subsequent backups will be much faster due to deduplication.

#### Snapshot Exclusion Issues
**Problem**: Backup includes unwanted `.snapshots` directories
**Cause**: Btrfs snapshots should be excluded
**Solution**: Global ignore rules are configured:
```bash
# Check ignore rules
sudo kopia policy show --global | grep -A5 "Ignore rules"

# Add ignore rule if missing
sudo kopia policy set --global --add-ignore ".snapshots/"
```

### Verification Commands

Check backup integrity:
```bash
# Verify repository
sudo kopia repository validate-provider

# Check snapshot consistency
sudo kopia snapshot verify <snapshot-id>

# Show repository statistics
sudo kopia content stats
```

Monitor S3 storage:
```bash
# Check S3 bucket contents
aws s3 ls s3://myhomelab-backups --recursive --human-readable

# Check lifecycle transitions
aws s3api get-bucket-lifecycle-configuration --bucket myhomelab-backups
```

Test notifications:
```bash
# Test notification system
curl -X POST "http://homelab.local:8080/homelab-alerts" \
    -H "Title: Backup Test" \
    -H "Priority: 3" \
    -H "Tags: backup,test" \
    -d "Testing Kopia backup notification system"
```

## Current Backup Status

### Repository Statistics
- **Total Size**: ~141 GB (before compression/deduplication)
- **Stored Size**: ~97 KB (after deduplication and compression)
- **Compression Ratio**: Excellent due to Kopia's deduplication
- **Snapshots**: 3 active (1 per subvolume)
- **Retention**: 10 daily + 12 monthly snapshots

### Storage Costs
- **S3 Standard**: First 24 hours (~$0.023/GB/month)
- **S3 Glacier**: After 24 hours (~$0.004/GB/month)
- **Estimated Monthly Cost**: <$10 for full retention

## Backup Logs

Logs are available through multiple channels:

### Service Logs
```bash
# Real-time logs
journalctl -u kopia-backup.service -f

# Recent logs
journalctl -u kopia-backup.service --since "1 day ago"

# Failed runs only
journalctl -u kopia-backup.service --since "1 week ago" | grep -i error
```

### File Logs
```bash
# Main backup log
tail -f /var/log/kopia-backup.log

# Search for errors
grep -i error /var/log/kopia-backup.log
```

### Notification History
Check ntfy web interface or mobile app for backup notification history.

## Maintenance

### Daily (Automated)
- Backup execution and verification
- Automatic snapshot cleanup per retention policy
- Repository maintenance and optimization

### Weekly Tasks
- Review backup logs for errors or warnings
- Monitor S3 storage usage and costs
- Verify notification delivery

### Monthly Tasks
- Test restore procedure on sample data
- Review and update backup retention policies
- Update Kopia to latest version if available

### Quarterly Tasks
- Full disaster recovery test
- Review S3 lifecycle policies
- Audit backup security and access controls

## Security Features

- **Client-side Encryption**: AES256-GCM-HMAC-SHA256
- **Repository Password**: Stored securely in `/etc/default/kopia-backup`
- **AWS Credentials**: Separate from backup password
- **Access Control**: Root-only access to backup operations
- **Network Security**: HTTPS for all S3 communications
- **Data Integrity**: BLAKE2B hashing for corruption detection

---

*Last updated: 2025-10-30*
*System status: ✅ Operational*
*Next backup: Daily at 2:00 AM*
