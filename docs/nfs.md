# NFS Shared Folders Documentation

## Overview

This document details the setup and configuration of NFS shared folders implemented on the homelab system. Two directories are shared via NFS:

1. A dedicated shared folder created as a Btrfs subvolume on the bcache device
2. The existing media library directory

These exports enable seamless file sharing and media access between the homelab server and client machines.

## Storage Configuration

### Shared Directories Details

| Directory | Mount Point | Subvolume | Device | Mount Options | Purpose | Access |
|-----------|-------------|-----------|--------|---------------|---------|--------|
| Shared Folder | `/storage/shared` | `@shared` | bcache0 (UUID: bb631e57-a7dd-41f5-bd22-92ab4bf0999f) | `defaults,noatime,compress=zstd:3,space_cache=v2,subvol=@shared` | Project files, backups, general file sharing | Read/Write |
| Media Library | `/storage/media` | `@media` | bcache0 (UUID: bb631e57-a7dd-41f5-bd22-92ab4bf0999f) | `defaults,noatime,compress=zstd:3,space_cache=v2,subvol=@media` | Movies, TV shows, and other media content | Read-Only |

### File Structure Update

```plaintext
/storage
|-- Immich
|   |-- database
|   |-- model-cache
|   |-- uploads
|-- data
|   |-- adguard
|   |-- authentik
|   |-- bazarr
|   |-- jellyfin
|   |-- jellyseerr
|   |-- ntfy
|   |-- portainer
|   |-- prowlarr
|   |-- qbittorrent
|   |-- radarr
|   |-- sonarr
|   |-- tdarr
|   |-- traefik
|   `-- uptime-kuma
|-- media
|   |-- anime
|   |-- download
|   |-- downloads
|   |-- movies
|   `-- tv
|-- nextcloud
`-- shared  # New NFS shared folder
```

### Btrfs Subvolume Layout

```plaintext
bcache0 (bb631e57-a7dd-41f5-bd22-92ab4bf0999f)
├── @data        → /storage/data
├── @media       → /storage/media
├── @nextcloud   → /storage/nextcloud
├── @immich      → /storage/Immich
└── @shared      → /storage/shared
```

## NFS Server Configuration

### Package Installation

```bash
sudo apt update
sudo apt install nfs-kernel-server
```

### Export Configuration

Location: `/etc/exports`

```plaintext
/storage/shared 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
/storage/media 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
```

### NFS Service Management

```bash
# Apply configuration changes
sudo exportfs -a

# Restart service
sudo systemctl restart nfs-kernel-server

# Enable service on boot
sudo systemctl enable nfs-kernel-server
```

### Firewall Configuration

If UFW is enabled:

```bash
sudo ufw allow from 192.168.1.0/24 to any port nfs
```

## Snapshot Configuration

### Snapper Setup

```bash
# Snapper configuration for shared folder
sudo snapper -c shared create-config /storage/shared
```

### Snapshot Settings

Location: `/etc/snapper/configs/shared`

```plaintext
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_LIMIT_HOURLY="1"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="4"
TIMELINE_LIMIT_MONTHLY="2"
SPACE_LIMIT="0.25"
FREE_LIMIT="0.2"
SUBVOLUME="/storage/shared"
```

## Client Configuration

### Fedora Client Setup

1. Package installation:
   ```bash
   sudo dnf install nfs-utils
   ```

2. Mount point creation:
   ```bash
   sudo mkdir -p /mnt/homelab-shared
   sudo mkdir -p /mnt/homelab-media
   ```

3. FSTAB configuration:
   Location: `/etc/fstab`
   ```plaintext
   192.168.1.2:/storage/shared /mnt/homelab-shared nfs rw,_netdev,auto,soft,noatime 0 0
   192.168.1.2:/storage/media /mnt/homelab-media nfs ro,_netdev,auto,soft,noatime 0 0
   ```

4. SELinux configuration:
   ```bash
   sudo setsebool -P use_nfs_home_dirs 1
   ```

### Performance Optimization Options (Optional)

Server-side optimization (`/etc/exports`):
```plaintext
/storage/shared 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash,rsize=1048576,wsize=1048576)
```

Client-side optimization (`/etc/fstab`):
```plaintext
192.168.1.2:/storage/shared /mnt/homelab-shared nfs rw,_netdev,auto,soft,noatime,rsize=1048576,wsize=1048576,vers=4.2 0 0
```

## Maintenance Procedures

### NFS Server Maintenance

- **Daily Operations**:
  - Check NFS service status: `sudo systemctl status nfs-kernel-server`
  - Monitor connected clients: `showmount -a localhost`
  - List all exported directories: `showmount -e localhost`

- **Weekly Tasks**:
  - Check for storage usage: `df -h /storage/shared /storage/media`
  - Review logs for any issues: `sudo journalctl -u nfs-server`

- **Monthly Maintenance**:
  - Review and update exports if needed
  - Verify snapshot rotation is working correctly
  - Check for any security updates for NFS

### Troubleshooting

Common issues and resolutions:

1. **Connection issues**:
   - Check if NFS service is running: `systemctl status nfs-kernel-server`
   - Verify network connectivity: `ping client-ip-address`
   - Check firewall settings: `sudo ufw status`

2. **Permission issues**:
   - Check file ownership/permissions: `ls -la /storage/shared/ /storage/media/`
   - On Fedora client, check SELinux: `getsebool -a | grep nfs`

3. **Performance issues**:
   - Test write performance (shared folder): `dd if=/dev/zero of=/mnt/homelab-shared/testfile bs=1M count=1024 oflag=direct`
   - Test read performance (media folder): `dd if=/mnt/homelab-media/some_large_file of=/dev/null bs=1M count=1024 iflag=direct`
   - Consider adjusting rsize/wsize parameters

## Emergency Recovery

If NFS service fails:
```bash
sudo systemctl restart nfs-kernel-server
sudo exportfs -ra
```

If mount points become inaccessible:
```bash
# For shared folder
sudo umount -f /mnt/homelab-shared
# For media folder
sudo umount -f /mnt/homelab-media
# Remount all
sudo mount -a
```

If data corruption occurs:
1. For shared folder:
   - Check snapper snapshots: `sudo snapper -c shared list`
   - Restore from snapshot: `sudo snapper -c shared undochange NUMBER..NUMBER+1 /storage/shared/path/to/file`

2. For media folder:
   - Check available snapshots: `sudo snapper -c media list` (assuming you have a snapper configuration for media)
   - Restore from snapshot: `sudo snapper -c media undochange NUMBER..NUMBER+1 /storage/media/path/to/file`
