# Incident: NVMe Storage Exhaustion

| Field      | Detail                                                                                              |
| ---------- | --------------------------------------------------------------------------------------------------- |
| **Date**   | March 20, 2026                                                                                      |
| **Status** | Investigation in progress (March 25, 2026)                                                          |
| **Impact** | NVMe dropped from ~172GB free to ~100GB free overnight. Risk of full disk causing service failures. |

---

## Timeline

| Time                        | Event                                                                                                                                                                           |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Pre-incident                | NVMe free space: ~172GB                                                                                                                                                         |
| Mar 16                      | Kernel upgraded 6.18.7 → 6.19.7, power management changes applied (max_cstate, tuned, powertop)                                                                                 |
| Mar 16 → Mar 20             | Storage silently growing at ~8GB/hr                                                                                                                                             |
| Mar 20 morning              | Sudden drop to ~100GB free noticed                                                                                                                                              |
| Mar 20 cleanup              | Removed all Docker images, containers, logs, and Snapper snapshots → **824GB free recovered**                                                                                   |
| Mar 20 → Mar 23             | Space consumed again: 824GB → 192GB free (632GB consumed over 3 days)                                                                                                           |
| Mar 23 re-investigation     | Deleted remaining snapshots → 192GB → 273GB free (81GB from snapshots)                                                                                                          |
| Mar 23 test                 | Stopped all running containers → 273GB → **885GB free instantly (612GB freed)**                                                                                                 |
| Mar 23                      | All services restarted — 884GB free, hourly storage monitor deployed                                                                                                            |
| Mar 24 morning              | Growth still at ~8GB/hr confirmed by storage monitor logs                                                                                                                       |
| Mar 24                      | Beszel confirmed growth started exactly **Mar 16** — day of kernel upgrade + power changes                                                                                      |
| Mar 24                      | Broken container healthchecks fixed (paperless-tika, zitadel-login, outline)                                                                                                    |
| Mar 24                      | NVMe APST disabled via udev rule — growth continued at same rate                                                                                                                |
| Mar 24                      | Snapper config tightened (root: daily only, data: hourly×4)                                                                                                                     |
| Mar 24                      | nodatacow migration on `@docker` — growth continued at same rate                                                                                                                |
| Mar 24                      | nodatacow reverted — confirmed it doubled storage due to lost reflink sharing (63GB → 131GB)                                                                                    |
| Mar 24                      | Clean baseline established: all services running, no snapshots, **Used: 63GB**                                                                                                  |
| Mar 25 morning              | Third batch (8 services) grew from 58GB → 111GB overnight (~6GB/hr)                                                                                                             |
| Mar 25 09:54                | Service isolation test started — each suspect service run individually for 16 min                                                                                               |
| Mar 25 ~12:16               | **Checkmate identified as primary culprit** — only service with continuous growth (~10GB/hr)                                                                                    |
| Mar 25 12:53                | All services restarted excluding checkmate — 68 containers, **Used: 63.28GB**                                                                                                   |
| Mar 25 20:48                | **Confirmed: 8 hours without checkmate, Used: 63.71GB** — essentially zero growth                                                                                               |
| Mar 25 20:49                | powertop --auto-tune re-enabled, dirty_writeback_centisecs changed 500→1500 (only tunable changed)                                                                              |
| Mar 25 20:55                | Reboot with full March 16th config restored (APST enabled, powertop, deep C-states)                                                                                             |
| Mar 25 20:55–21:30          | 68 containers (no checkmate), Used: 63.72GB → 64.18GB — stable post-reboot                                                                                                      |
| Mar 25 21:30                | Storage stable at 64.18GB — ~35 min after reboot (68 containers, no checkmate)                                                                                                  |
| **Mar 25 ~21:40**           | **Fresh checkmate install** — old containers, images, and data (`/storage/data/checkmate`) removed. New image pulled, clean MongoDB. **Baseline: 64.19GB Used, 70 containers.** |
| Mar 25 21:40 – Mar 26 10:09 | Fresh checkmate with empty MongoDB, no monitors configured: 64.19GB → 65.91GB (+1.72GB in ~12.5hrs, ~0.14GB/hr)                                                                 |
| Mar 26 ~10:10               | Added 3 uptime monitors (Immich, NextCloud, Jellyfin)                                                                                                                           |
| Mar 26 10:14                | Used: 66.11GB — already +0.2GB in ~5 min after adding monitors. Growth accelerating.                                                                                            |
| Mar 26 12:19                | Used: 71.60GB — +5.49GB in ~2hrs with 3 monitors (~2.7GB/hr)                                                                                                                    |
| Mar 26 12:22                | Added 3 more monitors (adguard, karakeep, zitadel) — 6 total. Used: 71.70GB                                                                                                     |
| Mar 26 13:18                | Used: 80.98GB — **+9.28GB in 56 min with 6 monitors (~10GB/hr)**. Matches original growth rate.                                                                                 |

---

## Key Observations

- Growth started **exactly March 16** — confirmed via Beszel logs
- Growth rate: **~8GB/hr** consistently
- Stopping **all** containers frees 600+ GB instantly
- Stopping **individual** containers frees almost nothing (<0.5GB each)
- `du` shows ~63GB, btrfs `Used` grows to 800+ GB — the gap is invisible CoW history
- Same snapper config ran fine for 6 months before March 16
- btrfs `Used` with CoW (63GB) vs nodatacow (131GB) confirms Docker images heavily share blocks via reflinks
- **Checkmate is the only service with continuous non-stop growth** (~10GB/hr in isolation)
- All other services show only a one-time startup spike then stabilize
- **Growth rate scales linearly with monitor count**: 0 monitors: ~0.14GB/hr, 3 monitors: ~2.7GB/hr, 6 monitors: ~10GB/hr. Each monitor adds ~1.6GB/hr of CoW accumulation. Active monitoring drives MongoDB writes which cause btrfs CoW extent buildup.
- Correlation with March 16th changes is still unexplained — checkmate was running before that date without causing growth. Something changed on March 16th that triggered or amplified checkmate's write behavior

---

## What Changed on March 16th

On March 16, multiple things changed simultaneously:

1. **Kernel upgraded from 6.18.7 → 6.19.7** (Fedora 43 system update)
2. **Power management changes applied**:
   - Removed `processor.max_cstate=1` from kernel parameters → CPU now enters C2 idle
   - Activated `tuned` balanced profile
   - Ran `powertop --auto-tune` → enabled NVMe APST, PCIe power management, and other tunables

The root cause has not been isolated yet. Any of these changes (or a combination) could be responsible.

---

## Experiments

### Experiment 1: NVMe APST Disable (March 24)
- **Hypothesis:** NVMe APST causes bursty writes that amplify CoW
- **Action:** Disabled APST via udev rule `/etc/udev/rules.d/99-nvme-apst-disable.rules`
- **Result:** Growth continued at ~8GB/hr. **Not the cause.**

### Experiment 2: Snapper Config Tightening (March 24)
- **Hypothesis:** Reducing snapshot retention reduces CoW accumulation
- **Action:** Root: daily×7, monthly×2 only. Data: hourly×4, daily×7, monthly×4
- **Result:** Growth continued at same rate. Snapshots amplify the issue but are not the root cause.

### Experiment 3: nodatacow on @docker (March 24)
- **Hypothesis:** Disabling CoW on Docker's subvolume eliminates the hidden space growth
- **Action:** Migrated `/var/lib/docker` to nodatacow via script
- **Result:** Growth continued at ~7.5GB/hr. Additionally, nodatacow **doubled** physical storage usage (63GB → 131GB) because Docker image layers can no longer share blocks via reflinks. **Not the fix. Reverted.**

### Experiment 4: Isolating the culprit service (March 24–25)

**Phase 1 — Batch testing:**
- **Baseline:** 62.64GB Used, 0 containers, 0 snapshots (March 24, 20:45)
- **0 containers, 30 min:** 62.63GB — zero growth
- **Batch 1** (traefik, postfix, cloudflared, adguard, jellyfin, beszel, ntfy, immich, zitadel — 15 containers): zero growth after 30 min
- **Batch 2** (arcane, sonarr, radarr, prowlarr, bazarr, qbit, seerr, nextcloud, onlyoffice, flaresolverr — 31 containers): went down (arcane cleaned images), zero growth after hours
- **Batch 3** (affine, checkmate, kuma, it-tools, flood, karakeep, n8n, stirling-pdf — 45 containers): 58GB → 111GB overnight (~6GB/hr). **Culprit is in this batch.**

**Phase 2 — Individual service isolation** (`isolate-service-growth.sh`):

| Service       | 16 min growth            | Pattern                                   |
| ------------- | ------------------------ | ----------------------------------------- |
| kuma          | +0.01GB                  | flat                                      |
| it-tools      | +0.04GB                  | flat                                      |
| flood         | +0.12GB                  | flat                                      |
| karakeep      | +0.88GB                  | startup spike, then flat                  |
| n8n           | +0.50GB                  | startup spike, then flat                  |
| stirling-pdf  | +1.29GB                  | startup spike, then flat                  |
| **checkmate** | **+1.47GB and climbing** | **continuous non-stop growth (~10GB/hr)** |

**Preliminary result:** Checkmate is the only service showing continuous growth in isolation. All others stabilize after startup.

**Phase 3 — Confirmation test: CONFIRMED**
- All services running **except checkmate** — 68 containers
- **Baseline:** 63.28GB Used at 12:53 on March 25
- **Result at 20:48:** 63.71GB Used — **+0.43GB over 8 hours** (essentially zero growth)
- **Checkmate confirmed as the sole cause of ~8-10GB/hr btrfs CoW growth**

**Open questions:**
- Why did checkmate's behavior change on March 16th? It was running before that date without causing growth.
- Is there a relation between the kernel/power changes and checkmate's write pattern?
- Was checkmate's image auto-updated by Watchtower around March 16th?
- How to run checkmate without the continuous CoW accumulation?

### Experiment 5: powertop --auto-tune VM tunables check (March 25)
- **Hypothesis:** powertop's `--auto-tune` changed VM dirty writeback tunables, causing more frequent CoW generations
- **Action:** Enabled powertop service, compared VM tunables before and after
- **Result:** powertop only changed `dirty_writeback_centisecs` from 500 (5s) → 1500 (15s). All other dirty tunables unchanged. This means **less** frequent writeback, not more — opposite of what would amplify CoW. **Unlikely to be the trigger.**
- **Note:** powertop was not active after reboots (oneshot service, disabled). The 8-hour stable test without checkmate ran with default tunables (500), proving powertop's tuning is not required to reproduce the fix.

### Experiment 6: Restore processor.max_cstate=1 (pending, deprioritized)
- **Hypothesis:** Locking CPU to C1 restores pre-March-16 writeback timing and stops excessive CoW accumulation
- **Action:** Add `processor.max_cstate=1` back to kernel cmdline, reboot, observe for 2-3 hours
- **Expected:** If growth stops, the changed CPU idle behavior is the root cause

### Experiment 7: Disable Snapper (pending, deprioritized)
- **Hypothesis:** Without snapshots, old CoW extents are freed automatically; growth stops or slows
- **Note:** Continuous growth pattern (not hourly jumps) suggests snapper is unlikely to be the primary cause
- **Action:** Disable snapper timeline creation, delete all snapshots, observe for 2-3 hours
- **Expected:** If growth stops, snapshots are still amplifying despite continuous writes

### Experiment 8: Boot previous kernel (last resort)
- **Hypothesis:** Kernel 6.19 has a subtle btrfs behavior change
- **Action:** Boot previous kernel from GRUB, observe for 2-3 hours
- **Expected:** If growth stops, kernel is the cause — file a bug report

---

## Actions Taken (confirmed fixes)

### Broken Container Healthchecks
| Container        | Problem                                                      | Fix                                                   |
| ---------------- | ------------------------------------------------------------ | ----------------------------------------------------- |
| `paperless-tika` | `apache/tika:latest` upgraded to v3; container crash-looping | Pinned to `apache/tika:2.9.2.1`                       |
| `paperless-tika` | Image has no `curl`; healthcheck used curl                   | Changed to `bash -c 'echo > /dev/tcp/localhost/9998'` |
| `zitadel-login`  | PAT file `root:root 640`; container runs as UID 1000         | `chmod 644 login-client.pat`                          |
| `outline`        | `SECRET_KEY` was base64; now requires 64-char hex            | Regenerated with `openssl rand -hex 32`               |

### Docker Log Rotation
Applied `max-size: 50m`, `max-file: 3` in `/etc/docker/daemon.json`

### Hourly Storage Monitor
- **Script**: `/HOMELAB/scripts/storage-monitor.sh`
- **Logs**: `/storage/data/logs/storage-monitor/YYYY-MM-DD.log` (14-day retention)
- **Cron**: `0 * * * * /HOMELAB/scripts/storage-monitor.sh`

---

## Current State (March 26, 10:14)

- Full March 16th config restored: kernel 6.19, deep C-states, powertop auto-tune, NVMe APST enabled
- 70 containers running including fresh checkmate with 6 monitors (Immich, NextCloud, Jellyfin, adguard, karakeep, zitadel)
- **Used: 80.98GB** at 13:18 — growth rate ~10GB/hr with 6 monitors, matching original incident rate
- Snapper config tightened but snapper still active
- Checkmate excluded from `start-all.sh` via `-e checkmate` flag (manually started for this test)

## Research: MongoDB + btrfs CoW (Perplexity analysis, March 25)

- MongoDB/WiredTiger is a known worst-case workload for btrfs CoW: constant small random writes to data files, journals, and WiredTiger internal structures
- MongoDB maintainers explicitly recommend XFS over btrfs for WiredTiger
- On btrfs: every MongoDB overwrite creates new extents (FS-level CoW on top of WiredTiger's application-level CoW = "double CoW")
- overlay2 copy-up semantics and long-lived file descriptors keep old extents alive
- Snapper snapshots further prevent old extent reclamation
- powertop's dirty_writeback change (500→1500) actually *reduces* flush frequency — opposite of what would amplify CoW. **Ruled out as trigger.**
- Kernel 6.19 has no documented btrfs CoW semantic changes; recent work focused on ENOSPC/reservation improvements which may let the leak run *further* but don't create it
- Most likely remaining explanation: checkmate image update or a subtle kernel btrfs interaction

## Next Steps

1. **Monitor checkmate growth** — checkmate started at 09:30 March 26, baseline 64.18GB. Compare after 1-2 hours to confirm reproduction.
2. **Check Watchtower logs** — determine if checkmate image was auto-updated around March 16th
3. **Find a fix for checkmate** — options: move MongoDB data to nodatacow directory, XFS loopback mount, or ext4 volume
4. Remaining experiments (max_cstate, snapper, kernel) deprioritized — only if checkmate behavior still unexplained
