# Off-site Backups (Backblaze B2)

This document details the off-site backup strategy for the homelab, which uses Kopia to provide disaster-recovery protection with deduplication, encryption, and incremental snapshots to **Backblaze B2** (via its S3-compatible API).

> **History:** Backups previously targeted AWS S3 with a Glacier Deep Archive lifecycle. That repository was abandoned on 2026-06-22 after the AWS access key was deactivated (`The AWS Access Key Id you provided does not exist in our records`) and the data had already transitioned to Glacier Deep Archive (unrecoverable without working creds). The repository was rebuilt fresh on Backblaze B2.

## Configuration Files

| File Type               | Location                                                                                   | Deployed To                                |
| ----------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------ |
| **Backup Script**       | [`./configs/scripts/kopia-backup.sh`](../../configs/scripts/kopia-backup.sh)               | `/usr/local/bin/kopia-backup.sh`           |
| **Systemd Service**     | [`./configs/systemd/kopia-backup.service`](../../configs/systemd/kopia-backup.service)     | `/etc/systemd/system/kopia-backup.service` |
| **Systemd Timer**       | [`./configs/systemd/kopia-backup.timer`](../../configs/systemd/kopia-backup.timer)         | `/etc/systemd/system/kopia-backup.timer`   |
| **Environment Config**  | [`./configs/defaults/kopia-backup.env`](../../configs/defaults/kopia-backup.env)           | `/etc/default/kopia-backup`                |
| **Notification Config** | [`./configs/defaults/notification-settings`](../../configs/defaults/notification-settings) | `/etc/default/notification-settings`       |

> `kopia-backup.env` is **gitignored** (contains the repository password + B2 application key). The repository credentials are also stored in `/root/.config/kopia/repository.config` after `kopia repository connect`.

## Backup Strategy

The backup system follows the **3-2-1 rule** by creating an off-site, encrypted, deduplicated copy of critical subvolumes.

- **Technology**: Kopia — block-level deduplication, compression, and client-side encryption
- **Storage**: Backblaze B2 bucket `redripper`, reached via the S3-compatible API (`s3.us-east-005.backblazeb2.com`)
- **Encryption**: AES256-GCM-HMAC-SHA256 client-side encryption with the repository password
- **Deduplication**: Content-defined chunking (BLAKE2B hashing) — only changed blocks ever upload
- **Compression**: `zstd-fastest` (global policy)
- **Incremental Backups**: Inherent to Kopia. Every run is incremental + deduplicated; identical content is never re-uploaded. There is no separate "full vs incremental" toggle.
- **Retention**: **10 daily + 4 weekly + 3 monthly** snapshots, auto-pruned (see below)
- **Exclusions**: Btrfs snapshot directories (`.snapshots/`, `/.snapshots`) are ignored globally
- **Maintenance**: Full maintenance runs daily to reclaim space from expired snapshots (B2 is hot storage — no Glacier workaround needed)
- **Logging**: All actions logged to `/var/log/kopia-backup.log`
- **Notifications**: Success/failure notifications via ntfy

## Configuration

### Repository Settings
- **Provider**: Backblaze B2 over the **S3-compatible API** (Kopia's native `b2` provider is deprecated)
- **Bucket**: `redripper`
- **Endpoint / Region**: `s3.us-east-005.backblazeb2.com` / `us-east-005`
- **Owner**: `root@redripper` (snapshots are created as root by the systemd service; maintenance also runs as root, the repo's designated maintenance owner)

### Retention Policy

Set as the global Kopia policy:

```bash
kopia policy set --global \
  --keep-latest 1 \
  --keep-hourly 0 \
  --keep-daily 10 \
  --keep-weekly 4 \
  --keep-monthly 3 \
  --keep-annual 0
```

Retention is applied automatically when each new snapshot is created (expired snapshot manifests are dropped); the daily **full maintenance** run then garbage-collects the now-unreferenced content blobs, physically shrinking storage.

### Maintenance Policy

```bash
kopia maintenance set \
  --enable-full=true --enable-quick=true \
  --full-interval=24h --quick-interval=1h
```

The backup script also forces a `kopia maintenance run --full` at the end of each backup.

### Backup Targets

| Subvolume         | Status   | Typical Size | Description                                 |
| ----------------- | -------- | ------------ | ------------------------------------------- |
| `/storage/data`   | ✅ Active | ~154 GB      | Docker service configs/DBs (incl. ~144 GB OpenCloud drive files) |
| `/storage/Immich` | ✅ Active | ~127 GB      | Photo and video library                     |

> `/storage/media` (Jellyfin library), `/storage/shared`, and the rest of `/storage` are **not** backed up off-site.

## Management Commands

### Manual Backups
```bash
# Run backup for all configured subvolumes (as root)
sudo /usr/local/bin/kopia-backup.sh

# Check repository status
sudo kopia repository status

# List all snapshots
sudo kopia snapshot list
```

### Monitoring
```bash
# View live backup logs
tail -f /var/log/kopia-backup.log

# Check systemd service status / recent logs
systemctl status kopia-backup.service
journalctl -u kopia-backup.service --since "1 day ago"

# Show the active global policy (retention, ignore rules, compression)
sudo kopia policy show --global

# Repository content / storage stats
sudo kopia content stats
```

### Repository Management
```bash
# Run full maintenance manually (applies retention GC)
sudo kopia maintenance run --full

# Show cache info / clear cache
sudo kopia cache info
sudo kopia cache clear

# Reconnect from scratch (creds in /etc/default/kopia-backup)
sudo KOPIA_PASSWORD=... kopia repository connect s3 \
  --bucket=redripper \
  --endpoint=s3.us-east-005.backblazeb2.com \
  --region=us-east-005 \
  --access-key=<B2_KEY_ID> \
  --secret-access-key=<B2_APPLICATION_KEY>
```

## Restore Procedure

### Step 1: List Available Snapshots
```bash
sudo kopia snapshot list                  # all snapshots
sudo kopia snapshot list /storage/data    # for a specific path
```

### Step 2: Restore Options

#### Full Directory Restore
```bash
sudo kopia snapshot restore <snapshot-id> /tmp/restored-data
```

#### Selective File Restore (mount)
```bash
sudo mkdir /mnt/kopia-snapshot
sudo kopia mount <snapshot-id> /mnt/kopia-snapshot
cp /mnt/kopia-snapshot/path/to/file /desired/location
sudo umount /mnt/kopia-snapshot
```

#### Browse via Web UI
```bash
sudo kopia server start --address=0.0.0.0:51515
# then browse at http://homelab.local:51515
```

### Step 3: Verify and Replace
After restoration, verify integrity before replacing originals.
```bash
diff -r /storage/data /tmp/restored-data
```

## Scheduling

Backups are automated via systemd timer, daily at 02:00 with a 30-minute randomized delay.

```bash
systemctl list-timers kopia-backup.timer   # check schedule
sudo systemctl enable --now kopia-backup.timer
sudo systemctl start kopia-backup.service   # run now (blocks until finished)
```

## Troubleshooting

#### Repository Connection Errors
```bash
sudo kopia repository status
# If disconnected, reconnect via the S3-compatible endpoint (see Repository Management)
```
If B2 rejects the key, re-issue an Application Key in the Backblaze console and update `/etc/default/kopia-backup` (and the gitignored `configs/defaults/kopia-backup.env`).

#### Permission Errors During Backup
Some files (live databases, locked files) may be unreadable. These are logged and skipped; the rest of the data is still backed up.

#### "maintenance must be run by designated user"
Maintenance must run as the repository owner (`root@redripper`). The script and the systemd service both run as root, so this should not occur. If you connected as a different user, run maintenance as root.

#### Btrfs `.snapshots` Included
Global ignore rules exclude them:
```bash
sudo kopia policy show --global | grep -A3 "Ignore rules"
# re-add if missing:
sudo kopia policy set --global --add-ignore ".snapshots/" --add-ignore "/.snapshots"
```

## Storage Costs (Backblaze B2)

- **Storage**: ~$6/TB/month ($0.006/GB/month). At ~281 GB ⇒ **~$1.70/month**.
- **Egress**: First 3× average daily storage is free per day; restores beyond that are ~$0.01/GB.
- No retrieval delays or storage-class restrictions (unlike the old Glacier setup).

---

*Last updated: 2026-06-22*
*System status: ✅ Migrated to Backblaze B2 (S3-compatible API)*
*Retention: 10 daily + 4 weekly + 3 monthly · Daily at 02:00*
