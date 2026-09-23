# PerfMTK

**A high-performance, native systemless optimization engine for MediaTek devices with Mali GPUs**

[![GitHub Downloads](https://img.shields.io/github/downloads/JUANIMAN/PerfMTK/total)](https://github.com/JUANIMAN/PerfMTK/releases)
[![Join the Telegram group](https://img.shields.io/badge/PerfMTK%20Telegram%20group-blue?style=flat-square&logo=telegram)](https://t.me/PerfMTK_chat)
[![Current Version](https://img.shields.io/badge/version-v16.3-success?style=flat-square)](https://github.com/JUANIMAN/PerfMTK/releases/latest)

## Overview

PerfMTK is an advanced Magisk / KernelSU / APatch module backed by an ultra-lightweight native C daemon (`perfmtkd`) and a rich CLI (`perfmtk`). Engineered specifically for MediaTek Dimensity and Helio platforms, it grants total, fine-grained control over CPU clusters, Mali GPUs, LPDDR memory buses, hardware touch digitizers, thermal curves, and storage subsystems.

With sub-millisecond profile transitions, an event-driven `epoll` reactor (< 3.0 MB RSS, 0.0% idle CPU), and deep multi-OEM compatibility, PerfMTK unlocks maximum gaming frame rates (120 FPS stable) and exceptional daily battery endurance.

---

## Features

* **Universal SoC & Multi-OEM Support**:
  * Auto-calibrated for all MediaTek CPU topologies: All-Big-Core (Dimensity 9400/9300), Tri-Cluster (Dimensity 9200/9000/8300), Dual-Cluster (Dimensity 8200/8100/7000, Helio G99/G95/G90T), and entry-level SoCs.
  * Universal compatibility verified across Xiaomi/POCO (HyperOS/MIUI), OnePlus/OPPO/Realme (ColorOS/OxygenOS), Vivo/iQOO (OriginOS/FuntouchOS), Samsung (One UI), Motorola (HelloUI/MyUX), Transsion (Infinix XOS/Tecno HiOS), and AOSP.
* **Native C Engine & In-Memory Daemon (`perfmtkd`)**:
  * Event-driven `epoll` reactor running on only 2 threads with < 3.0 MB RSS and 0.0% idle CPU overhead.
  * In-memory configuration caching for sub-millisecond hardware switching latency.
  * 4-tier foreground app detection: LSPosed hook (`PerfMTK-Hook`), Netlink Process Connector (`cn_proc`), kernel `cgroup.procs` inotify, and adaptive debounced fallback.
* **Hardware Touch & Digitizer Booster**:
  * Native kernel-level touch sampling rate unlock (480Hz / 2160Hz) via direct digitizer `ioctl` (`/dev/xiaomi-touch`, `/proc/touchpanel`, `/sys/class/touch/touch_dev`, Samsung TSP).
  * Host-side `THP Smooth` filter integration to eliminate gesture jitter.
  * Touch input IRQs and dispatchers kept unpinned to Little cores, preventing frame preemption on Big cores and ensuring rock-solid **120 FPS** in AAA games (PUBG Mobile, Wuthering Waves, Genshin Impact).
* **Smart Fast Charge Bypass & Battery Care**:
  * Dedicated gaming thermal bypass: charges at full speed without thermal throttle, keeping battery cells cool (31°C - 36°C even under sustained 120 FPS gaming loads).
  * Automated battery safety guard with configurable emergency cutoff (45°C - 55°C, default 52°C).
  * **Battery Care** engine: configurable charge ceiling (50% - 100%, default 80%) to maximize lithium cell health over years.
  * Instant access via Android Quick Settings Tiles.
* **Predictive Thermal Guardian**:
  * Proactive thermal slope algorithm ($\Delta T / \Delta t$) that detects rapid temperature rises before hardware throttling kicks in.
  * Smooth, graduated frequency and uclamp steps that eliminate the infamous "sawtooth" throttling stutter.
* **Advanced MediaTek Hardware Knobs**:
  * **DRAM DVFSRC LPDDR5X**: Direct memory bus scaling with clocks up to 8533 MHz for memory-intensive titles.
  * **Mali GPU & GED HAL**: Dynamic frequency scaling and margin tuning for modern 5.x and 6.x kernels (`dvfs_margin_value`, `gpu_boost_level`).
  * **MediaTek Game Boost Engine (GBE)**: Automated foreground game process acceleration and thermal headroom reserve.
  * **FPSGO Sysfs**: Adaptive tuning for `/sys/kernel/fpsgo` on Android 14, 15, and 16.
  * **UFS Storage I/O Optimization**: `simple_ondemand` clock governors and queue depth tuning for seamless open-world texture streaming.
* **Full-Featured Terminal CLI & Interactive TUI (`perfmtk`)**:
  * Colorized dashboard, live telemetry, hardware inspection, profile editing, and backup/restore management.
* **Companion App**: Seamless integration with the [PerfMTK-Manager](https://github.com/JUANIMAN/PerfMTK-Manager) Flutter companion app (Bento HUD, live thermal graphs, Quick Settings tiles).

---

## Compatibility & Requirements

* **Processor**: MediaTek SoC with a Mali GPU (Dimensity or Helio series).
* **Android OS**: Android 9.0 (Pie) up to Android 15 / 16.
* **Linux Kernel**: Version 4.14.x up to 6.1.x+.
* **Root Manager**: Magisk (v27+ recommended), KernelSU, or APatch.

> [!IMPORTANT]
> **KernelSU & APatch Users:**  
> Ensure your environment has a magic mount helper module installed (e.g., **Hybrid Mount** or **Mountify**) to guarantee proper module filesystem overlay support.

---

## Installation

1. Download the latest release `.zip` from the [Releases page](https://github.com/JUANIMAN/PerfMTK/releases/latest).
2. Flash the `.zip` in Magisk, KernelSU, or APatch.
3. **Smart Installation Modes**:
   * **Express Mode (Recommended)**: Wait 10 seconds (or press `[VOL-]`) for an optimal automatic setup tuned to your RAM and SoC.
   * **Custom Mode**: Press `[VOL+]` within 10 seconds to selectively customize `system.prop`, `post-fs-data.sh`, or `service.sh`.
4. Reboot your device to apply all kernel and daemon settings.

---

## Automatic Profile Switching (Daemon Setup)

The native daemon automatically switches profiles when apps enter the foreground:

1. *(Optional but Recommended)* Install the [LSPosed framework](https://github.com/JingMatrix/LSPosed).
2. Install the **PerfMTK-Hook** companion app.
3. Enable **PerfMTK-Hook** inside the LSPosed manager.
4. If LSPosed is not used, the daemon will seamlessly and automatically fall back to its internal kernel Netlink process connector and cgroup inotify engine with zero configuration required!

### App Profile Directives (`app_profiles.conf`)

Located at `/data/adb/modules/perfmtk/config/app_profiles.conf` (with compatibility link at `/data/local/app_profiles.conf`):

```ini
# Format: package_name=energy_profile;key=value

# Default global profile when no specific rule matches
DEFAULT_PROFILE=balanced

# Profile applied when the screen turns off
SCREEN_OFF_PROFILE=powersave
APP_DEBOUNCE_MS=2000

# High-performance games with touch acceleration and thermal bypass
com.tencent.ig=performance;thermal=off;touch=game
com.kurogame.wutheringwaves.global=performance;thermal=off;touch=game
com.miHoYo.GenshinImpact=performance;thermal=off;touch=game

# Daily and media apps
com.whatsapp=balanced
com.android.chrome=balanced
com.netflix.mediaclient=powersave
```

---

## CLI Usage (`perfmtk`)

Run the interactive console dashboard (requires root):
```bash
su -c perfmtk
```

### Profile Commands
```bash
su -c perfmtk performance   # Apply performance profile
su -c perfmtk balanced      # Apply balanced profile
su -c perfmtk powersave     # Apply power-saving profile
su -c perfmtk powersave+    # Apply ultra power-saving profile
```

### Smart Fast Charge Bypass
```bash
su -c perfmtk --charge-bypass on      # Force fast charging bypass during games
su -c perfmtk --charge-bypass off     # Restore standard charging behavior
su -c perfmtk --charge-bypass status  # Query bypass state and battery temperature
su -c perfmtk --charge-bypass reset   # Revert manual override to active profile rule
```

### Battery Care
```bash
su -c perfmtk --battery-care on 80    # Enable charge limiter at 80%
su -c perfmtk --battery-care off       # Disable charge limiter
su -c perfmtk --battery-care status   # Query Battery Care state
```

### Predictive Thermal Guardian
```bash
su -c perfmtk --tg on 75 2            # Enable Guardian (Target 75°C, max 2 clamp steps)
su -c perfmtk --tg off                # Disable Guardian
su -c perfmtk --tg status             # Query current thermal slope and clamp level
```

### OEM Thermal Management
```bash
su -c perfmtk thermal disable         # Disable OEM thermal throttling services
su -c perfmtk thermal enable          # Re-enable OEM thermal throttling services
su -c perfmtk thermal status          # Query OEM thermal state
```

### Telemetry & Automation
```bash
su -c perfmtk -s                      # Formatted live hardware status
su -c perfmtk -s --json               # Machine-readable JSON output
su -c perfmtk --stream 1000           # Continuous real-time JSON stream (1000ms interval)
su -c perfmtk --backup                # Backup configuration profiles
su -c perfmtk --restore               # Restore profiles from backup
```

---

## Profile Configuration Reference

Profiles are stored in `/data/adb/modules/perfmtk/config/` (`performance.conf`, `balanced.conf`, `powersave.conf`, `powersave+.conf`). All parameters can be tuned manually or via PerfMTK-Manager:

```ini
[CPU]
GOVERNOR="schedutil schedutil schedutil"
DOWN_RATE_LIMIT_US="1000 1000 1000"
UP_RATE_LIMIT_US="1000 1000 1000"
CORE_CONFIG="cpu0:4:4|cpu4:3:3|cpu7:1:1"
MAX_FREQS="2200000 2660000 2700000"
MIN_FREQS="1800000 2300000 2400000"

[GPU]
GPU_FREQ=800000
GPU_GOVERNOR="userspace"

[DEVFREQ]
DVF_GOVERNOR="userspace"
DRAM_FREQ=8533000

[UFS]
UFS_GOVERNOR="simple_ondemand"
UFS_CLK_ENABLE=1

[FPSGO]
FORCE_ONOFF=1
BOOST_TA=1

[GBE]
ENABLE=1
POLICY_MASK=7
HEADROOM=50

[UCLAMP]
TOP_APP_MIN=96
TOP_APP_MAX=1024

[THERMAL_CHARGE]
BYPASS_CHARGE_THROTTLE=1
UNLOCK_FPS_THERMAL=1
BATTERY_TEMP_CUTOFF=52

[TOUCH]
GAME_MODE=1
THP_SMOOTH=1
```

---

## License & Disclaimer

* **License**: This project is licensed under the [GNU GPLv3 License](LICENSE).
* **Disclaimer**: PerfMTK modifies low-level hardware registers and kernel interfaces. While built with robust thermal and voltage safeguards, the developers assume no liability for hardware damage or instability resulting from improper use.
