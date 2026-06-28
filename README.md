# PerfMTK

**A high-performance systemless optimization module for MediaTek devices with Mali GPUs**

[![GitHub Downloads](https://img.shields.io/github/downloads/JUANIMAN/PerfMTK/total)](https://github.com/JUANIMAN/PerfMTK/releases)
[![Join the Telegram group](https://img.shields.io/badge/PerfMTK%20Telegram%20group-blue?style=flat-square&logo=telegram)](https://t.me/PerfMTK_chat)

## Overview

PerfMTK is a Magisk/KernelSU/APatch module designed to maximize performance and power efficiency on MediaTek devices. By managing CPU clusters, GPU configurations, I/O schedulers, and thermal engines, PerfMTK provides complete and granular control over your hardware.

---

## Features

* **MediaTek SOC Tailored Optimizations**: Custom adjustments tuned specifically for MediaTek platforms.
* **Automatic Hardware Detection**: Dynamically identifies CPU topology (big.LITTLE cluster layouts), Mali GPU models, FPSGO engine paths, and UFS platform configurations.
* **Granular Profile Configurations**: Easily edit custom configurations via clean, user-friendly `.conf` files.
* **Persistent Settings Storage**:
  * Device hardware configuration: `/data/adb/modules/perfmtk/config/device.conf`
  * Active energy profiles: `/data/adb/modules/perfmtk/config/profiles/*.conf`
* **Tailored Power Profiles**:
  * `performance` – Maximum hardware output for gaming and demanding apps.
  * `balanced` – Default profile balancing smoothness and battery longevity.
  * `powersave` – Standard battery-saving tweaks.
  * `powersave+` – Aggressive throttling for maximum battery duration.
* **Thermal Engine Control**: Option to toggle system-level thermal limitations (throttling limits).
* **Storage Speedups**: Optimized I/O request parameters for UFS storage nodes.

---

## Compatibility & Requirements

* **Processor**: MediaTek SoC with a Mali GPU.
* **Android OS**: Android 9.0 (Pie) or higher.
* **Linux Kernel**: Version 4.14.x or higher.
* **Root Managers**: Magisk (v27+ recommended), KernelSU, or APatch.

> [!IMPORTANT]
> **Attention KernelSU & APatch Users:**  
> If you are using newer root solutions. It is highly recommended to install a magic mount helper module (like **Hybrid Mount** or **Mountify** module) to ensure proper filesystem mount capabilities.

---

## Installation

1. Ensure you have a supported root manager installed (Magisk, KernelSU, or APatch).
2. Download the latest release `.zip` from the [Releases page](https://github.com/JUANIMAN/PerfMTK/releases/latest).
3. Flash the `.zip` package using your root manager app.
4. During installation, select your preferred features using the Volume keys:
   * `system.prop` tweaks
   * `post-fs-data.sh` configurations
   * `service.sh` system adjustments
   * **PerfMTK Daemon** (for app-specific profiles)
5. Reboot your device to apply the modifications.

---

## Automatic Profile Switching (Daemon Setup)

If you chose to install the **PerfMTK Daemon**, you can automatically switch energy profiles depending on the active foreground application:

1. Install the [LSPosed framework](https://github.com/JingMatrix/LSPosed) (if not already installed).
2. Install the [PerfMTK-Hook](https://www.pling.com/p/1670559/) LSPosed companion app.
3. Open the LSPosed manager and ensure the **PerfMTK-Hook** module is enabled.
4. Reboot your device to activate automatic, app-aware profile shifting!

### App-Specific Mapping

The daemon monitors apps and maps them using `/data/local/app_profiles.conf`. You can customize this file manually or manage it via the [PerfMTK Manager app](https://github.com/JUANIMAN/PerfMTK-Manager).

Example file configuration:
```ini
# Configuration file for PerfMTK Daemon
# Format: package_name=energy_profile

# Default global profile when no matching app is in the foreground
DEFAULT_PROFILE=balanced

com.tencent.ig=performance
com.miHoYo.GenshinImpact=performance
com.whatsapp=balanced
com.android.chrome=balanced
com.netflix.mediaclient=powersave
```

---

## Module Components

| Component | Description |
| :--- | :--- |
| **system.prop** | Optimizes UI rendering properties to improve visual smoothness. |
| **post-fs-data.sh** | Core settings applied early in boot (cpuset, virtual memory, memory management). |
| **service.sh** | Boot-completed service optimizing MTK PPM and storage interface files. |
| **perfmtk_daemon** | Background listener that detects app focus and applies corresponding power profiles. |

> [!WARNING]
> Running the background daemon requires continuous focus polling, which may slightly increase standby power consumption. For maximum battery conservation, consider running the module without installing the daemon.

---

## Usage

### Command Line Interface (e.g. Termux)

Run the main menu (requires root):
```bash
su -c perfmtk
```

Get system options and commands:
```bash
su -c perfmtk --help
```

#### Manual Profile Application
```bash
su -c perfmtk performance   # Apply performance profile
su -c perfmtk balanced      # Apply balanced profile
su -c perfmtk powersave     # Apply saving profile
su -c perfmtk powersave+    # Apply extreme saving profile
```

#### Thermal Throttling Control
```bash
su -c thermal_limit enable   # Re-enable standard temperature controls
su -c thermal_limit disable  # Bypass thermal throttle caps (Watch your temps!)
```

#### Advanced Engine Commands
```bash
perfmtk --detect               # Scan hardware and build device.conf
perfmtk --generate             # Build default active profile files
perfmtk --list                 # View existing config profiles
perfmtk --info                 # Show hardware detection details
perfmtk --status               # Monitor live core frequencies & status
perfmtk --edit <profile>       # Edit a configuration profile
perfmtk --validate <profile>   # Scan profile for formatting/value issues
perfmtk --backup               # Backup existing configs
perfmtk --restore              # Restore configs from backup
```

### Profile Configuration Format

Profiles are saved in INI format. You can customize them to lock down frequencies, Governors, and options:

```ini
[CPU]
# Sets governors and rate limits per cluster policy.
# One GOVERNOR value applies to all policies; multiple values follow CPU policy order.
GOVERNOR="schedutil schedutil"
# One value applies to all policies; multiple values follow CPU policy order.
DOWN_RATE_LIMIT_US="1000 1000"
UP_RATE_LIMIT_US="1000 1000"
# Optional individual override by policy index.
POLICY_1_GOVERNOR=schedutil
POLICY_1_UP_RATE_LIMIT_US=20000

CORE_CONFIG="cpu0:4:4|cpu4:4:0"
MAX_FREQS="2000000 1800000"
MIN_FREQS="500000 500000"

[GPU]
GPU_OPP_INDEX=-1
GPU_GOVERNOR="dummy"

[DEVFREQ]
DVF_GOVERNOR="userspace"

[UFS]
UFS_GOVERNOR="simple_ondemand"
UFS_CLK_ENABLE=1

[FPSGO]
FORCE_ONOFF=2
BOOST_TA=0
```

---

## Troubleshooting

1. Always check that you are running the latest release of **PerfMTK**.
2. Avoid setting custom frequencies/governors that are not listed in your generated `device.conf`.
3. If the **PerfMTK Manager App** fails to load profiles, double-check that you granted Root permission inside your Root Manager dashboard.
4. If you face any issues, please open a ticket on the [GitHub Issues page](https://github.com/JUANIMAN/PerfMTK/issues).

> [!CAUTION]
> Bootloops can occasionally occur when flashing system properties on certain highly modified custom ROMs. If your device bootloops, remove the module folder `/data/adb/modules/perfmtk` via recovery terminal or safe mode. Consult the [Magisk FAQ](https://topjohnwu.github.io/Magisk/faq.html) for detailed recovery steps.

---

## Community & Support

Join the community for quick support, feature testing, and configuration sharing:
* [![Telegram Chat](https://img.shields.io/badge/Telegram-PerfMTK%20Chat-blue?logo=telegram&style=flat-square)](https://t.me/PerfMTK_chat)

---

## License & Disclaimer

* **License**: This project is licensed under the [GNU GPLv3 License](LICENSE).
* **Disclaimer**: Use this module at your own risk. Overclocking/throttling modifications can cause heat or stability issues. The developer is not responsible for any bricked devices or hardware damage.
