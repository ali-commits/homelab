# Incident: NVMe Storage Exhaustion

| Field      | Detail                                                                                              |
| ---------- | --------------------------------------------------------------------------------------------------- |
| **Date**   | March 20, 2026                                                                                      |
| **Status** | Resolved — root cause identified and fixed (March 24, 2026)                                         |
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
| Mar 24 investigation    | Beszel confirmed growth started **Mar 16** — correlated with power management reboot          |
| Mar 24                  | Identified two containers with broken healthchecks hammering btrfs every 30s — both fixed     |

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

**3. NVMe APST — confirmed root cause (March 24)**
Beszel confirmed storage growth began on **March 16** — exactly when power management changes were made. Investigation traced it to `powertop --auto-tune` enabling **NVMe APST (Autonomous Power State Transition)**.

APST allows the NVMe to enter low-power sleep states when idle. On a server running btrfs + snapper, this has a compounding effect:
- With APST: NVMe buffers writes and flushes them in large bursts → btrfs creates large CoW extents in one transaction
- Each hourly snapper snapshot captures that large CoW state → holds far more unique extents than before
- Snapper cleanup deletes old snapshots but can't keep pace with the larger-per-snapshot accumulation
- Net result: ~8GB/hour persistent growth, invisible to `du` and `docker system df`

Before March 16, the NVMe was always active (no APST), writes were small and frequent, and each snapshot held a manageable amount of data — stable for 6 months with the same snapper config.

**Fix**: APST permanently disabled via udev rule `/etc/udev/rules.d/99-nvme-apst-disable.rules`. On a 24/7 server the power saving (~0.5W) is not worth the storage impact.

**4. Broken container healthchecks (contributing factor — March 24)**
Two containers had broken healthchecks firing every 30 seconds, generating additional btrfs writes:

| Container        | Problem                                                                                                                     | Fix                                                   |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| `paperless-tika` | `apache/tika` image has no `curl`; healthcheck used `curl -f http://localhost:9998/tika`                                    | Changed to `bash -c 'echo > /dev/tcp/localhost/9998'` |
| `zitadel-login`  | PAT file was `root:root 640`; container runs as UID 1000 → `Permission denied` on startup; healthcheck failing indefinitely | Fixed file permissions: `chmod 644 login-client.pat`  |

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

- [x] **Identify root cause** — NVMe APST confirmed and disabled (March 24)
- [x] **Identify broken healthchecks** — `paperless-tika` and `zitadel-login` fixed (March 24)
- [x] **Reduce snapper frequency** — root changed to daily-only, data changed to hourly keep-4 (March 24)
- [ ] **Monitor storage after reboot** to confirm the APST fix holds and growth rate returns to near-zero

---

## Prevention

1. **NVMe APST disabled** via udev rule — the primary cause; do not re-enable via `powertop --auto-tune`
2. **Snapper limits tightened** — root: daily×7 only; data: hourly×4 only; no monthly snapshots
3. **Docker log rotation** configured (50MB max, 3 files) — prevents unbounded log growth
4. **Hourly storage monitor** at `/storage/data/logs/storage-monitor/` catches growth early
