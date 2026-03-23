# Incident: NVMe Storage Exhaustion

| Field      | Detail                                                                                              |
| ---------- | --------------------------------------------------------------------------------------------------- |
| **Date**   | March 20, 2026                                                                                      |
| **Status** | Mitigated — root cause under investigation                                                          |
| **Impact** | NVMe dropped from ~172GB free to ~100GB free overnight. Risk of full disk causing service failures. |

---

## Timeline

| Time                    | Event                                                                                         |
| ----------------------- | --------------------------------------------------------------------------------------------- |
| Pre-incident            | NVMe free space: ~172GB                                                                       |
| Mar 20 morning          | Sudden drop to ~100GB free noticed                                                            |
| Mar 20 investigation    | Free space further at ~108GB and dropping                                                     |
| Mar 20 cleanup          | Removed all Docker images, containers, logs, and Snapper snapshots → **824GB free recovered** |
| Mar 20 → Mar 23         | Space gradually consumed again: 824GB → 192GB free (632GB consumed over 3 days)               |
| Mar 23 re-investigation | Deleted remaining snapshots → 192GB → 273GB free (81GB from snapshots)                        |
| Mar 23 test             | Stopped all running containers → 273GB → **885GB free instantly (612GB freed)**               |
| Mar 23                  | All services restarted — currently 884GB free, monitoring in place                            |

---

## Root Cause Analysis

### The Filesystem: btrfs + Docker overlay2

The NVMe runs a single **btrfs** filesystem hosting all subvolumes (`@`, `@docker`, `@var`, `@data`, etc.). Docker uses the **overlay2** storage driver on top of this btrfs volume.

### Why Space Disappears

btrfs uses **Copy-on-Write (CoW)**: every write creates new extents rather than modifying in-place. Docker's overlay2 driver writes heavily to container writable layers, generating a constant stream of btrfs extents. Old extents are retained as long as anything references them — including Snapper snapshots.

This creates two compounding sources of hidden space consumption:

**1. Snapper snapshots locking old extents**
Each hourly/daily snapshot of `@` and `@data` freezes all btrfs extents that existed at that moment. Any Docker writes after the snapshot create new extents, while the snapshot holds the old ones. Over days, this accumulates silently — `du` shows normal sizes but `btrfs filesystem usage` shows hundreds of GB "Used".

**2. Running container overlay2 layers**
Even without snapshots, running containers accumulate btrfs CoW history in their overlay2 upper directories. This was demonstrated conclusively on March 23: stopping all containers freed **612GB instantly** — space that `du` and `docker system df` could not account for.

### The Numbers

| Metric                                | Value     |
| ------------------------------------- | --------- |
| btrfs `Used` (at peak)                | ~840GB    |
| `du -shx` across all subvolumes       | ~106GB    |
| Gap (CoW history)                     | ~734GB    |
| Freed by stopping containers          | **612GB** |
| Freed by deleting snapshots           | **81GB**  |
| Docker images (docker system df)      | 39GB      |
| overlay2 on disk (du)                 | 86–90GB   |
| Difference (CoW overhead in overlay2) | ~47–50GB  |

---

## What We Did

### March 20 (initial cleanup)
1. Deleted all Snapper snapshots except the most recent (`root #2429`, `data #2428`)
2. Stopped all Docker containers
3. Removed all Docker images, containers, and unbounded log files
   - `checkmate_mongodb` had a **2GB unbounded log file**
4. Applied Docker log rotation: `max-size: 50m`, `max-file: 3` in `/etc/docker/daemon.json`
5. Re-pulled all images and restarted all services
6. Result: **824GB free**

### March 23 (re-investigation)
1. Deleted all remaining Snapper snapshots → +81GB freed
2. Stopped all containers → +612GB freed instantly (confirmed containers are the primary driver)
3. Removed all containers (`docker container prune`)
4. Restarted all services
5. Deployed hourly storage monitor script (see [Monitoring](#monitoring))

---

## Monitoring

A cron job runs every hour at `:00` to track disk usage and identify growing overlay2 directories.

- **Script**: `/HOMELAB/scripts/storage-monitor.sh`
- **Logs**: `/storage/data/logs/storage-monitor/YYYY-MM-DD.log` (14-day retention)
- **Cron**: `0 * * * * /HOMELAB/scripts/storage-monitor.sh`

The log captures:
- Disk free/used
- `docker system df` summary
- Top 15 overlay2 directories by size **mapped to container names**
- Any container log files exceeding 50MB

**Current top consumers at restart (baseline, March 23):**

| Container               | overlay2 size |
| ----------------------- | ------------- |
| onlyoffice              | 5.1GB         |
| immich_machine_learning | 4.7GB         |
| infisical_backend       | 2.9GB         |
| stirling-pdf            | 2.3GB         |
| linkwarden              | 2.2GB         |
| immich_server           | 2.1GB         |
| paperless-gotenberg     | 1.8GB         |
| n8n                     | 1.7GB         |

---

## Known Gaps / Next Steps

- [ ] **Identify the specific container(s)** causing the 612GB accumulation — monitor logs over the next 24–48 hours to see which overlay2 directory grows fastest
- [ ] **Long-term fix**: Move Docker's `@docker` subvolume to a separate **ext4 or xfs** partition — this eliminates btrfs CoW accumulation entirely for container layers
- [ ] **Consider disabling Snapper for `@` (root)** or reducing frequency — root snapshots have little recovery value compared to the space cost on a btrfs+Docker system
- [ ] **Investigate onlyoffice** — 5.1GB overlay2 at a clean start is already the largest; likely writes a lot to its container layer

---

## Prevention

1. **Docker log rotation** is now configured (50MB max, 3 files) — prevents unbounded log growth
2. **Hourly storage monitor** will catch growth early before disk fills
3. **Do not run Snapper snapshots frequently** on a btrfs volume that hosts Docker — CoW history compounds rapidly
