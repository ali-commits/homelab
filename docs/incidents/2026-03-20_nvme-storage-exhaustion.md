# Incident: NVMe Storage Exhaustion

| Field          | Detail                                                                                              |
| -------------- | --------------------------------------------------------------------------------------------------- |
| **Date**       | March 20, 2026                                                                                      |
| **Status**     | ⚠️ Root cause identified — checkmate removed, ghost storage partially reclaimed. Two open items remain. |
| **Impact**     | NVMe dropped from ~172GB free to ~0GB free over several weeks. Risk of full disk causing service failures. |
| **Root Cause** | MongoDB 8.2.5 (tcmalloc-google) SIGSEGV crash loop on kernel 6.19 → 2,000+ WiredTiger journal recovery cycles → btrfs CoW extent accumulation. |
| **Open Items** | 1. ~26GB ghost storage still on NVMe above pre-incident baseline. 2. Checkmate needs a fix to run on kernel 6.19 (MongoDB pin or kernel patch). |

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
| Mar 26 13:33                | Phase 1 investigation complete. Used: 83.24GB. Arcane DB queried — **checkmate image was last updated March 7** (backend) and **March 5** (mongo). No update on or near March 16. Image update theory ruled out. |
| Mar 26 13:38–14:13          | **Phase 2 investigation.** Used: 89.80GB at 14:13. MongoDB SIGSEGV crash loop discovered — **1,861+ container restarts**, exit code 139, every ~31 seconds. Each crash triggers WiredTiger journal recovery on restart, rewriting all dirty pages. This is the primary CoW accumulation mechanism. MongoDB 8.2.5 segfaults on kernel 6.19 — explains March 16th correlation exactly. |
| Mar 26 15:12                | Experiment 10: THP set to `always`. No effect — crash loop continued. THP ruled out. Reverted to `madvise`. Used: 99.51GB. |
| Mar 26 15:31                | Kernel 6.18.7 downloaded from Koji and installed. Set as default boot kernel. |
| Mar 26 15:48                | **Rebooted into kernel 6.18.7.** Used: 98.26GB. RestartCount: 0. |
| Mar 26 15:50                | **Zero SIGSEGV crashes after 2 min on kernel 6.18.7.** MongoDB running stably. |
| Mar 26 15:55                | **Confirmed stable — zero crashes, zero SIGSEGV in 10 min. Used: 98.14GB (slight decrease).** Root cause definitively confirmed: **kernel 6.19 + MongoDB 8.2.5 incompatibility.** Power management is not the cause. |
| Mar 26 16:00                | Kernel 6.19.8 set as default. Checkmate stopped, containers and images removed (`docker compose down --rmi all`), `/storage/data/checkmate/` deleted. |
| Mar 26 16:09                | Rebooted back to kernel 6.19.8. Confirmed: 69 containers running, no checkmate, Used: 97.47GB. Investigation complete. |
| Mar 26 16:15–16:30          | Ghost storage cleanup: deleted 1,705 mongod coredumps (~4GB), ran `docker system prune` (178MB), deleted all 3 snapper snapshots, ran btrfs balance (2 passes). **Used: ~90.6GB.** ~26GB ghost storage remains above pre-incident baseline — btrfs background reclamation ongoing. |

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
- **Checkmate image update theory ruled out** — Arcane DB confirms last updates were March 7 (backend, digest `sha256:64028db...`) and March 5 (mongo). No image change on or near March 16. The same binary ran without growth from Mar 7–15, then triggered ~10GB/hr growth on Mar 16.
- **ROOT CAUSE IDENTIFIED (Phase 2):** MongoDB 8.2.5 (in `checkmate-mongo:latest`) is **segfaulting every ~31 seconds** (exit code 139, SIGSEGV). This produces 1,861+ crash-restart cycles. Each unclean crash triggers WiredTiger journal recovery on the next startup, which rewrites all dirty pages to disk, generating a burst of new btrfs CoW extents. The crash loop — not MongoDB's normal write patterns — is the primary driver of CoW accumulation.
- **March 16th correlation:** The SIGSEGV started on March 16th when both the kernel (6.18.7 → 6.19.7) and power/C-state config changed simultaneously. These have not been isolated experimentally yet.
- **ROOT CAUSE CONFIRMED (Experiment 11):** Rebooted into kernel 6.18.7 on March 26, 15:48. MongoDB crash loop stopped immediately — zero SIGSEGV events, RestartCount stayed at 0 for 10+ minutes. Storage stabilised and began decreasing. **Kernel 6.19 + MongoDB 8.2.5 is the confirmed incompatibility.** Power management is not a factor.

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

### Experiment 9: MongoDB crash-restart loop investigation (March 26, Phase 2) ✅ COMPLETE

**Method:** Docker events monitoring, coredump analysis via `coredumpctl`, systemd journal review.

**Findings:**
- `docker events` revealed MongoDB container dying with **exit code 139** (SIGSEGV) every ~31 seconds
- `docker inspect` was misleading — showed exit code 0 (previous clean restart); Docker events showed the real exit code
- `coredumpctl list mongod` confirmed **continuous coredumps** being generated and immediately rotated
- `journalctl` confirmed: `Process (mongod) of user 999 terminated abnormally with signal 11/SEGV`
- Coredump stack trace: crash in `libc.so.6 +0x188a15` (signal/abort handler) called from deep inside mongod internals — consistent with a WiredTiger internal assertion or memory corruption
- Container restart count: **1,861+ restarts** at time of discovery (container started Mar 25 ~21:40 = ~17 hours earlier = 1 crash every ~33 seconds, consistent)
- MongoDB runs for exactly ~31 seconds per cycle: startup (350ms) → journal recovery → normal operation → SIGSEGV → Docker restart → repeat
- `inotifywait` on `/storage/data/checkmate/mongodb/` during the cycle showed heavy writes to `WiredTiger.turtle` (~1/sec), journal files, and WiredTiger metadata on every startup — each recovery cycle rewrites dirty pages
- btrfs `filesystem du` on MongoDB data dir: 364MB logical — but each recovery cycle generates new CoW extents that btrfs cannot reclaim while the container is running
- MongoDB memory usage at crash: only ~115MB (not OOM) — pure segfault

**Mechanism confirmed:**
```
MongoDB starts → ~31s of operation → SIGSEGV crash
→ Docker restarts container
→ WiredTiger detects unclean shutdown (lock file not empty)
→ Journal recovery: replays all uncommitted writes → new btrfs CoW extents
→ FTDC interim file replayed → more writes
→ Repeat 1,800+ times
```

**Why growth scales with monitor count:** More active monitors → more MongoDB writes between crashes → more dirty pages in WiredTiger cache → more pages replayed during journal recovery → more CoW extents per cycle.

**Why it started March 16th:** MongoDB 8.2.5 (installed via image built March 6, deployed March 7) segfaults on kernel 6.19. The same binary ran cleanly on kernel 6.18 (zero crashes). The kernel upgrade on March 16th introduced the SIGSEGV crash loop.

**Result: ROOT CAUSE CONFIRMED.** The CoW growth is not from MongoDB's normal write patterns — it is driven entirely by the crash-restart loop and the btrfs CoW extents generated during each WiredTiger journal recovery.

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

## Current State (March 26, 16:30)

- **Running kernel 6.19.8** — rebooted back from 6.18.7 after confirming root cause
- 69 containers running — **checkmate fully removed** (containers, images, `/storage/data/checkmate/` deleted)
- **Used: ~90.6GB** — down from peak of ~103GB after cleanup (coredumps, Docker prune, btrfs balance)
- **Ghost storage: ~26GB above pre-incident baseline (~64GB with all services running minus checkmate)**
  - 1,705 mongod coredumps deleted (~4GB reclaimed)
  - Docker prune: 178MB reclaimed
  - btrfs balance (2 passes): ~7GB reclaimed
  - Remaining ~26GB: btrfs CoW history from 2,000+ crash-recovery cycles; will clear slowly in background as btrfs reclaims unreferenced extents
- **Root cause confirmed and investigation closed.** Two open items remain (see below).

## Open Items

### 1. Ghost Storage (~26GB)
btrfs CoW extents from the crash loop are still referenced in the extent tree. Active mitigation applied:
- All 3 snapper snapshots deleted (were holding old extents alive)
- 1,705 mongod coredumps deleted (~4GB)
- btrfs balance run (2 passes, ~7GB reclaimed)

Remaining options to accelerate reclamation:
- **Wait** — btrfs background reclamation will continue clearing over days/weeks
- **`btrfs balance start /`** (full balance, no filter) — more aggressive but takes longer and impacts I/O
- **Reboot** — clears in-memory extent caches and forces a fresh pass

### 2. Checkmate on Kernel 6.19 (pending fix)
Checkmate is currently removed. To restore it safely on kernel 6.19:
- **Option A: Pin MongoDB version** — override `checkmate-mongo:latest` to use MongoDB 7.x or a specific 8.x patch that doesn't SIGSEGV on kernel 6.19. Requires custom compose override or waiting for upstream checkmate to pin MongoDB.
- **Option B: Report upstream** — file a bug against bluewave-labs/checkmate or MongoDB JIRA for SIGSEGV on kernel 6.19 with tcmalloc-google. A kernel update to 6.20+ may also resolve it.
- **Option C: Stay on kernel 6.18** — functional workaround but means missing kernel security updates indefinitely.

## Research: MongoDB + btrfs CoW (Perplexity analysis, March 25)

- MongoDB/WiredTiger is a known worst-case workload for btrfs CoW: constant small random writes to data files, journals, and WiredTiger internal structures
- MongoDB maintainers explicitly recommend XFS over btrfs for WiredTiger
- On btrfs: every MongoDB overwrite creates new extents (FS-level CoW on top of WiredTiger's application-level CoW = "double CoW")
- overlay2 copy-up semantics and long-lived file descriptors keep old extents alive
- Snapper snapshots further prevent old extent reclamation
- powertop's dirty_writeback change (500→1500) actually *reduces* flush frequency — opposite of what would amplify CoW. **Ruled out as trigger.**
- Kernel 6.19 has no documented btrfs CoW semantic changes; recent work focused on ENOSPC/reservation improvements which may let the leak run *further* but don't create it
- **Confirmed root cause (Experiment 11):** Not a btrfs interaction — MongoDB 8.2.5 (tcmalloc-google) crashes with SIGSEGV on kernel 6.19, triggering a continuous crash-restart-recovery loop. The CoW growth is a side-effect of repeated WiredTiger journal recovery, not normal MongoDB write patterns.

## Investigation Log

### Phase 1: Image update investigation ✅ COMPLETE
1. **Check Arcane logs** ✅ — Arcane DB (`auto_update_records`) queried directly. Last checkmate updates: backend Mar 7, mongo Mar 5. **No update on or near March 16.**
2. **Inspect checkmate image build date** ✅ — Backend image built **2026-03-06**, mongo built **2026-02-17**. Both well before March 16.
3. **Check checkmate GitHub releases** — review bluewave-labs/checkmate for code changes around March 16th (polling frequency, DB write patterns, logging changes)

**Phase 1 conclusion: Checkmate image update theory RULED OUT.** The same image ran without issue from Mar 7–15. Growth started Mar 16 coinciding exclusively with the kernel upgrade + power management changes. **Kernel 6.19 or C-state/PCIe power changes now the primary suspects.**

### Phase 2: Write pattern analysis ✅ COMPLETE
4. **btrfs filesystem du on MongoDB data** ✅ — MongoDB data dir: 364MB logical. CoW accumulation happens at the btrfs extent level during journal recovery, not from normal writes.
5. **Real-time write monitoring** ✅ — `inotifywait` showed heavy writes to `WiredTiger.turtle` (~1/sec), journal files, and metadata during each crash-recovery cycle. These are recovery writes, not normal operation writes.
6. **MongoDB profiling** ✅ — MongoDB `serverStatus` shows near-zero opcounters per session because each session only lives ~31 seconds before crashing.

**Phase 2 conclusion: ROOT CAUSE CONFIRMED — MongoDB 8.2.5 SIGSEGV crash loop on kernel 6.19.** The crash-restart-recovery cycle (1,800+ times) is the primary driver of btrfs CoW extent accumulation, not MongoDB's steady-state write patterns.

### Phase 3: Fix validation (pending)
7. **nodatacow on MongoDB data directory only** — now less relevant since the crash loop (not write patterns) is the primary cause. Still worth testing as a secondary mitigation since journal recovery writes would also benefit from nodatacow.
8. ~~**Test previous checkmate image**~~ — ruled out, image unchanged since Mar 7
9. **Fix the SIGSEGV crash** — primary fix options:
   - **Downgrade MongoDB** — pin `checkmate-mongo` to a MongoDB version that doesn't segfault on kernel 6.19 (e.g., MongoDB 7.x or a specific 8.x patch)
   - **Downgrade kernel** — boot kernel 6.18, verify crash stops (Experiment 8)
   - **Find upstream fix** — check MongoDB JIRA / GitHub for known SIGSEGV with kernel 6.19 or specific glibc/tcmalloc combinations

### Experiment 10: THP = always (March 26, 15:12) ✅ COMPLETE
- **Hypothesis:** MongoDB startup warns `tcmalloc-google` wants `transparent_hugepage/enabled = always`; system had `madvise`. Wrong THP mode could cause memory corruption → SIGSEGV.
- **Baseline:** 15:12, Used: 99.51GB, restart count: 2020, THP: `madvise`
- **Action:** `echo always > /sys/kernel/mm/transparent_hugepage/enabled`
- **Result:** Crash loop continued unchanged. 5 more SIGSEGV crashes within 90 seconds (15:17–15:19). Used: 100.79GB. **THP setting is not the cause.** Reverted to `madvise`.

### Experiment 11: Boot kernel 6.18.7 (March 26, 15:48) ✅ COMPLETE — ROOT CAUSE CONFIRMED
- **Hypothesis:** MongoDB 8.2.5 SIGSEGV crash loop is caused by kernel 6.19, not power management.
- **Action:** Downloaded kernel-6.18.7-200.fc43 RPMs from Koji (not available in repos), installed with `rpm -ivh --force`, set as default boot kernel via `grubby`, rebooted.
- **Baseline on kernel 6.19:** crash every ~31 seconds, 2,020+ restarts, ~10GB/hr btrfs growth.
- **Result on kernel 6.18.7:**
  - 15:50 (2 min after boot): RestartCount = 0, zero SIGSEGV events
  - 15:55 (7 min after boot): RestartCount still 0, zero SIGSEGV in 10 min, Used: 98.14GB (decreasing)
  - MongoDB running stably with all 6 monitors active — no crashes
- **Conclusion: CONFIRMED. Kernel 6.19 + MongoDB 8.2.5 (tcmalloc-google) is the incompatible combination causing the SIGSEGV crash loop and all downstream btrfs CoW growth. Power management changes are not a factor.**

### Phase 4: Power/thermal isolation ✅ SUPERSEDED
Power management testing no longer needed — Experiment 11 (kernel 6.18 reboot) confirmed the kernel version is the sole cause. MongoDB runs stably on kernel 6.18 with the current power config unchanged, proving power management is not a factor.
