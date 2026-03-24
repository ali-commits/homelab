# Hardware Configuration

## 🖥️ System Overview

| Component  | Specification                                             | Notes                                      |
| ---------- | --------------------------------------------------------- | ------------------------------------------ |
| **CPU**    | AMD Ryzen Threadripper 2920X (12-core/24-thread @ 3.5GHz) | High-performance workstation processor     |
| **Memory** | 32GB DDR4                                                 | Excellent for containerized workloads      |
| **GPU**    | NVIDIA GeForce GTX 1070 (8GB VRAM)                        | Hardware transcoding & ML acceleration     |
| **OS**     | Fedora Linux 43 (Server Edition)                          | Modern server platform with latest drivers |
| **Uptime** | Typically high                                            | Stable 24/7 operation                      |

## 💾 Storage Hardware

### Primary Storage Devices
| Device      | Type     | Capacity | Purpose        | Health |
| ----------- | -------- | -------- | -------------- | ------ |
| **nvme0n1** | NVMe SSD | 1TB      | System storage | ✅ Good |
| **sda**     | HDD      | 3.6TB    | Data storage   | ✅ Good |

### GPU Hardware
| Component          | Specification           | Capabilities          |
| ------------------ | ----------------------- | --------------------- |
| **GPU**            | NVIDIA GeForce GTX 1070 | Pascal Architecture   |
| **VRAM**           | 8GB GDDR5               | High-bandwidth memory |
| **CUDA Cores**     | 1920                    | Parallel processing   |
| **Video Encoder**  | NVENC (H.264/H.265)     | Hardware transcoding  |
| **Driver Version** | 580.95.05               | Latest Fedora drivers |
| **CUDA Version**   | 13.0                    | ML framework support  |

### Storage Architecture
```
┌─────────────────┐    ┌─────────────────────────────────┐
│   System NVMe   │    │        Data Storage             │
│      1TB        │    │         (Single HDD)            │
│                 │    │                                 │
│ ┌─────────────┐ │    │ ┌─────────────────────────────┐ │
│ │ EFI (500MB) │ │    │ │ sda1 (3.6TB Btrfs)          │ │
│ └─────────────┘ │    │ └─────────────────────────────┘ │
│ ┌─────────────┐ │    │           │                     │
│ │Root (950GB) │ │    │           └── Multiple          │
│ │   Btrfs     │ │    │               Subvolumes        │
│ └─────────────┘ │    │         (media, immich, etc)    │
└─────────────────┘    └─────────────────────────────────┘

┌─────────────────────────────────┐
│         GPU Acceleration        │
│     NVIDIA GeForce GTX 1070     │
│                                 │
│ ┌─────────────┐ ┌─────────────┐ │
│ │Video Encode │ │ML/AI Compute│ │
│ │   NVENC     │ │    CUDA     │ │
│ └─────────────┘ └─────────────┘ │
└─────────────────────────────────┘
```
```
┌─────────────────┐    ┌─────────────────────────────────┐
│   System NVMe   │    │        Data Storage             │
│   (1TB)         │    │       (Single HDD)              │
│                 │    │                                 │
│ ┌─────────────┐ │    │ ┌─────────────────────────────┐ │
│ │ EFI (500MB) │ │    │ │ sda1 (3.6TB)                │ │
│ └─────────────┘ │    │ │ Btrfs Single                │ │
│ ┌─────────────┐ │    │ │                             │ │
│ │Root (1TB)   │ │    │ │ Media, Nextcloud, Immich    │ │
│ │   Btrfs     │ │    │ │ Shared Data                 │ │
│ └─────────────┘ │    │ └─────────────────────────────┘ │
└─────────────────┘    └─────────────────────────────────┘
```

## 🔍 Hardware Health Monitoring

### SMART Monitoring Status
| Drive       | Interface | Temperature | Health Status | Last Check |
| ----------- | --------- | ----------- | ------------- | ---------- |
| **nvme0n1** | NVMe PCIe | Monitored   | Hourly checks | Auto       |
| **sda**     | SATA HDD  | Monitored   | Hourly checks | Auto       |

### GPU Monitoring Status
| Component           | Monitoring Method | Frequency  | Health Status       |
| ------------------- | ----------------- | ---------- | ------------------- |
| **GPU Temperature** | nvidia-smi        | Real-time  | Auto-monitored      |
| **GPU Memory**      | nvidia-smi        | Real-time  | 8GB available       |
| **GPU Utilization** | nvidia-smi        | Real-time  | Ready for workloads |
| **Driver Status**   | nvidia-smi        | Boot check | ✅ 580.95.05         |

### GPU Temperature & Power
- **Current Temperature**: ~39°C (idle)
- **Power Draw**: 6W idle / 166W max
- **Thermal Management**: Automatic fan control
- **Power Efficiency**: Excellent for 24/7 operation

## ⚡ Performance Characteristics

### Performance Characteristics

### CPU Performance
- **Architecture**: AMD Zen+ (Threadripper)
- **Cores**: 12 cores / 24 threads
- **Base Clock**: 3.5GHz (4.3GHz boost)
- **Cache**: 32MB L3 cache
- **Suitable for**: Heavy containerized workloads, parallel processing

### Memory Performance
- **Total**: 32GB DDR4
- **Available**: ~30GB usable
- **Speed**: DDR4-2933 (high bandwidth)
- **Usage**: Typically <50% under normal load
- **Suitable for**: Multiple Docker services, databases, ML workloads

### GPU Performance
- **Architecture**: Pascal (GP104)
- **CUDA Cores**: 1920
- **Memory**: 8GB GDDR5 (256-bit bus)
- **Memory Bandwidth**: 256 GB/s
- **Video Encoding**: Hardware NVENC (H.264/H.265)
- **ML Performance**: Excellent for inference workloads
- **Suitable for**: Jellyfin transcoding, Immich ML, CUDA applications

### Storage Performance
### Storage Performance
| Storage Tier    | Read Speed | Write Speed | IOPS      | Use Case         |
| --------------- | ---------- | ----------- | --------- | ---------------- |
| **System NVMe** | ~3500 MB/s | ~3000 MB/s  | Very High | OS, apps, Docker |
| **HDD Storage** | ~150 MB/s  | ~120 MB/s   | Moderate  | Media, backups   |

### GPU Performance Benchmarks
| Workload              | Performance           | Use Case                     |
| --------------------- | --------------------- | ---------------------------- |
| **Video Transcoding** | 4-6x realtime (H.264) | Jellyfin media server        |
| **ML Inference**      | Excellent (CUDA 12.9) | Immich photo analysis        |
| **Compute Tasks**     | 1920 CUDA cores       | General GPGPU workloads      |
| **Memory Bandwidth**  | 256 GB/s              | High-throughput applications |

## 🔧 Hardware Management Commands

### System Information
```bash
# CPU information
lscpu

# Memory information
free -h

# Storage device information
lsblk -f

# PCI device information
lspci

# Hardware details
sudo dmidecode | less
```

### Temperature Monitoring
```bash
# CPU temperature (if sensors available)
sensors

# Drive temperatures
sudo smartctl -A /dev/sda | grep Temperature
sudo smartctl -A /dev/sdb | grep Temperature
sudo smartctl -A /dev/sdc | grep Temperature
```

### Hardware Health Checks
```bash
# SMART health check all drives
sudo smartctl -H /dev/nvme0n1 /dev/sda

# Detailed SMART info
sudo smartctl -a /dev/nvme0n1

# Memory test (memtest86+ - requires reboot)
# Available in GRUB menu

# CPU stress test
stress --cpu 12 --timeout 60s
```

### GPU Monitoring & Management
```bash
# GPU status and monitoring
nvidia-smi

# Real-time GPU monitoring
watch -n 1 nvidia-smi

# GPU temperature and utilization
nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv

# GPU details
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv

# Monitor GPU during workload
nvidia-smi dmon -s pucm

# Check CUDA capability
nvidia-smi --query-gpu=compute_cap --format=csv

# GPU topology
nvidia-smi topo -m
```

### GPU Use Cases
```bash
# Test GPU with Docker
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu20.04 nvidia-smi

# Monitor during transcoding
nvidia-smi dmon -s u -d 1  # Monitor utilization every second

# Check video encoding capabilities
ffmpeg -hwaccels  # List hardware accelerators
```

## BIOS/UEFI Configuration

### Current BIOS Version
| Component | Value |
|-----------|-------|
| **Motherboard** | ASUS ROG STRIX X399-E GAMING |
| **BIOS Version** | 1602 (Latest) |
| **BIOS Date** | 2024/03/08 |
| **Vendor** | American Megatrends Inc. |

### Known Firmware Issues
| Issue | Status | Mitigation |
|-------|--------|------------|
| **AMD-Vi IOAPIC not in IVRS** | BIOS bug, won't be fixed | IOMMU disabled via kernel parameter |
| **TPM ACPI region mismatch** | BIOS bug | TPM disabled in BIOS |

### Kernel Parameters
The following kernel parameters are configured in `/etc/default/grub`:
- `iommu=off` - Disables IOMMU due to AMD-Vi IOAPIC BIOS bug (see Known Firmware Issues)
- `modprobe.blacklist=nouveau,nova_core` - Use NVIDIA proprietary drivers

> **Note**: `processor.max_cstate=1` and `intel_idle.max_cstate=0` were previously set here but removed in March 2026 — they were unnecessarily locking the CPU to shallow idle states and causing high idle power draw.

### Disabled Hardware
Hardware disabled for server optimization:
- **WiFi (rtw88_8822be)** - Blacklisted in `/etc/modprobe.d/disable-wifi-bt.conf`
- **Bluetooth** - Blacklisted and service masked
- **TPM** - Device units masked due to firmware bug

### Disabled Services
Services disabled for server optimization (headless homelab):

| Service | Description | Reason |
|---------|-------------|--------|
| **udisks2** | Desktop disk manager | Not needed - server managed via SSH/Cockpit |
| **packagekit** | Desktop software update GUI | Not needed - updates via dnf CLI |
| **abrtd, abrt-oops, abrt-journal-core** | Automatic Bug Reporting Tool | Unnecessary overhead on homelab server |
| **pmcd, pmie, pmlogger, pmproxy** | Performance Co-Pilot monitoring | Not needed - using Uptime Kuma instead |
| **pmie_farm, pmlogger_farm** | PCP farm services | Part of PCP stack (disabled) |
| **systemd-homed** | Portable home directories | Not using portable home dirs |
| **systemd-homed-activate** | Home activation service | Masked - not using systemd-homed |
| **iscsi-onboot, iscsi-starter** | iSCSI initiator services | No SAN/iSCSI storage in use |
| **multipathd** | Multipath I/O daemon | No SAN multipath storage |

### Boot Target
- **Default target**: `multi-user.target` (no GUI)
- **Reason**: Headless server - all management via SSH, Cockpit, or Tailscale

---

## ⚡ Power Management

Configured in March 2026 to reduce idle power consumption and fan noise on the Threadripper 2920X.

### Power Profile Summary
| Setting | Value | Method |
|---|---|---|
| **CPU Governor** | `schedutil` | Default (kernel managed) |
| **Tuned Profile** | `balanced` | tuned service |
| **CPU Boost** | Disabled | systemd service `cpu-boost-disable` |
| **C-states available** | POLL, C1, C2 | Max for this platform (C6 not supported on X399/Zen+) |
| **NVMe Power Control** | `on` (APST **disabled**) | udev rule `/etc/udev/rules.d/99-nvme-apst-disable.rules` |

### Before vs After Results
| Metric | Before | After |
|---|---|---|
| **CPU Tdie (idle)** | ~50°C | ~41°C (-9°C) |
| **CPU Core Voltage** | 1.44V | 0.83–0.98V |
| **CPU Fan** | ~1670 RPM | ~1100 RPM (-33%) |
| **CPU OPT Fan** | ~1440 RPM | ~970 RPM (-33%) |
| **VRM Output Current** | 17–21A | 3–11A |
| **Max idle frequency** | 4141 MHz (boosting) | 3500 MHz (capped) |

### Installed Tools
| Package | Purpose |
|---|---|
| `tuned` + `tuned-adm` | System-wide power profile management |
| `powertop` | Power audit and auto-tune (USB autosuspend, PCIe ASPM) |
| `kernel-tools` | Provides `cpupower` and `turbostat` |

### Persistent Configuration
| Component | Location | Description |
|---|---|---|
| **Boost disable service** | `/etc/systemd/system/cpu-boost-disable.service` | Runs after tuned, writes `0` to `/sys/devices/system/cpu/cpufreq/boost` |
| **Tuned service** | `systemctl enable tuned` | Active on boot, profile: `balanced` |
| **PowerTOP auto-tune** | Applied at install time | USB autosuspend, PCIe ASPM, misc savings — **NVMe excluded** (see below) |

### BIOS Power Settings (ASUS ROG STRIX X399-E, BIOS 1602)
Path: **Advanced → AMD CBS → Zen Common Options**

| Setting | Value | Notes |
|---|---|---|
| **Global C-State Control** | Enabled | Unlocks C2 idle state |
| **Power Supply Idle Control** | Typical Current Idle | Required for C-states to engage; `Low Current Idle` causes instability on Linux |

> **Fan curves** configured in BIOS Q-Fan Control: ~30% duty cycle at ≤45°C, ramps above that.
> **Negative voltage offset** applied in Extreme Tweaker to reduce heat under load.

### NVMe APST — Disabled Intentionally

NVMe APST (Autonomous Power State Transition) was enabled by `powertop --auto-tune` on March 16, 2026. This caused the NVMe to buffer writes and flush them in large bursts, which compounded btrfs CoW accumulation: each hourly snapper snapshot captured a much larger CoW state than before, causing ~8GB/hour storage growth that exhausted the disk within days.

**APST is permanently disabled** via `/etc/udev/rules.d/99-nvme-apst-disable.rules`. Do not re-enable it. On a 24/7 server with btrfs + snapper, the power savings (~0.5W) are not worth the storage impact.

```bash
# Verify APST is disabled (should return "on")
cat /sys/class/nvme/nvme0/power/control
```

### Platform Limitations
- **C6 not available**: Threadripper 2920X (Zen+) on X399 does not expose C6 package sleep state at the firmware level. C2 is the deepest achievable idle state regardless of OS or BIOS configuration. Confirmed via `turbostat`: `Counter 'Core%c6' can not be added`.
- **EPP not available**: Energy Performance Preference requires Zen 2+ — not supported on this CPU.
- **No OS fan control**: `asus_wmi_sensors` exposes temperatures but not PWM registers for this board. Fan curves must be managed via BIOS Q-Fan only.

### Power Management Commands
```bash
# Check active tuned profile
tuned-adm active

# Check C-state availability
cat /sys/devices/system/cpu/cpu0/cpuidle/state*/name

# Check boost state (0=disabled, 1=enabled)
cat /sys/devices/system/cpu/cpufreq/boost

# Check boost disable service
systemctl status cpu-boost-disable

# Live power/C-state breakdown (5s sample)
sudo turbostat --interval 5 --show Pkg%pc6,Core%c6,CPU%c1,PkgWatt,CoreTmp

# Check CPU frequencies across all cores
grep MHz /proc/cpuinfo | awk -F: '{print $2}' | sort -n | uniq -c

# Full sensor readings
sensors
```
