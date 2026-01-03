# PerfMTK

**A Magisk module for MediaTek devices with Mali GPUs**

[![GitHub Downloads](https://img.shields.io/github/downloads/JUANIMAN/PerfMTK/total)](https://github.com/JUANIMAN/PerfMTK/releases)

## Overview

PerfMTK is a Magisk module specifically designed to optimize performance and power efficiency on MediaTek devices. With multiple profiles and advanced configurations, PerfMTK gives you complete control over your device's performance.

## Features

- **Specific optimizations** for MediaTek SOCs
- **Automatic hardware detection**: Detects CPU architecture (4, 8, 4+4, 6+2, 4+3+1), GPU type, FPSGO, and UFS availability
- **Customizable profile configurations**: Edit profile settings via easy-to-understand `.conf` files
- **Persistent configuration storage**:
  - Device config: `/data/adb/modules/perfmtk/config/device.conf`
  - Profile configs: `/data/adb/modules/perfmtk/config/profiles/*.conf`
- **Power modes**:
  - **`performance`** - Maximum performance
  - **`balanced`** - Balance between performance and battery
  - **`powersave`** - Battery saving
  - **`powersave+`** - Extreme battery saving
- **Thermal control** with option to enable/disable thermal limitations
- **I/O improvements** with parameter optimization for UFS storage

## Compatibility

- Device with MediaTek processor and Mali GPU
- Android 9.0 or higher
- Kernel version 4.14.x or higher
- Magisk 27 or higher installed

## Installation

1. Ensure you have Magisk or KernelSU installed on your MediaTek device
2. Download the latest PerfMTK zip file from the [releases page](https://github.com/JUANIMAN/PerfMTK/releases/latest)
3. Install the module via Magisk manager or KernelSU manager
4. During installation, you can choose which components to install:
   - system.prop
   - post-fs-data.sh
   - service.sh
   - PerfMTK Daemon
5. Reboot your device
6. Enjoy optimized performance!

## If install PerfMTK Daemon
For the best experience and battery life:
1. Install [LSPosed framework](https://github.com/JingMatrix/LSPosed/releases/download/v1.10.2/LSPosed-v1.10.2-7182-zygisk-release.zip) (if not already installed)
2. Install the [PerfMTK-Hook](https://www.pling.com/p/1670559/) LSPosed module
4. Reboot and enjoy automatic profile switching!

## Module Components

PerfMTK installs only what you choose during the installation process:

| Component | Description |
|------------|-------------|
| **system.prop** | Includes system property settings to increase smoothness |
| **post-fs-data.sh** | Contains settings for important components such as cpuset, vm, mm and sched |
| **service.sh** | Includes ppm and filesystem tweaks to improve overall performance |
| **perfmtk_daemon** | Background process that identifies foreground applications and applies energy profiles according to configuration |

> [!WARNING]
> The perfmtk_daemon runs in the background to provide app-specific profiles, which may slightly increase battery consumption. If battery life is your primary concern, consider using the module without this component.

### App-specific profiles with daemon

The PerfMTK Daemon uses a configuration file called **app_profiles.conf** (located by default at `/data/local/app_profiles.conf`) to assign specific profiles to different applications. You can modify it manually or use the [PerfMTK Manager app](https://github.com/JUANIMAN/PerfMTK-Manager).

The default content of the app_profiles.conf file is:

```
# Configuration file for PerfMTK Daemon  
# Format: package_name=energy_profile
  
# Default global profile when no application from the list is in the foreground  
DEFAULT_PROFILE=balanced
```

You can customize it to assign different profiles to your favorite applications, for example:

```
# Configuration file for PerfMTK Daemon
# Format: package_name=energy_profile

# Default global profile when no application from the list is in the foreground  
DEFAULT_PROFILE=balanced

com.tencent.ig=performance
com.miHoYo.GenshinImpact=performance
com.whatsapp=balanced
com.android.chrome=balanced
com.netflix.mediaclient=powersave
```

## Usage

### Via Terminal (e.g., Termux)
```bash
su -c perfmtk
```

Help:
```bash
su -c perfmtk --help
```

To change performance profiles manually:
```bash
# Maximum performance
su -c perfmtk performance

# Balanced (default)
su -c perfmtk balanced

# Battery saving
su -c perfmtk powersave

# Extreme battery saving
su -c perfmtk powersave+
```

For thermal limitation control:
```bash
# Enable thermal limitations
su -c thermal_limit enable

# Disable thermal limitations (be careful with overheating)
su -c thermal_limit disable
```

For configuration profiles:
```bash
su -c perfmtk --detect         # Detect device hardware
su -c perfmtk --generate       # Generate default profiles
su -c perfmtk --list           # List available profiles
su -c perfmtk --info           # Show device hardware info
su -c perfmtk --edit <profile> # Edit profile configuration
su -c perfmtk <custom_profile> # Apply custom profile
```

### Configuration File Format

Profiles use an intuitive INI-style format:
```ini
[CPU]
GOVERNOR="schedutil"
DOWN_RATE_LIMIT_US=1000
UP_RATE_LIMIT_US=1000
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

Edit these files to customize CPU frequencies, governors, GPU settings, and more!

### Via PerfMTK Manager App

1. Open the [PerfMTK Manager app](https://github.com/JUANIMAN/PerfMTK-Manager)
2. Select the desired performance profile
3. Enable or disable thermal limitations according to your needs
4. Configure specific profiles for your favorite applications

📥 **Download**: [Latest version of PerfMTK Manager](https://github.com/JUANIMAN/PerfMTK-Manager/releases/latest)

## Troubleshooting

If you encounter any issues:

1. Make sure you're using the latest version of PerfMTK
2. Do not set values outside those detected in the device configuration file.
3. If you are experiencing [issues with the PerfMTK-Manager](https://github.com/JUANIMAN/PerfMTK/issues/27#issuecomment-3264779857), please check whether the app has root access in your root manager.
4. If problems persist, please report the issue in the [GitHub issues section](https://github.com/JUANIMAN/PerfMTK/issues) with detailed information about your device and the problem you're experiencing.
5. [![Join the Telegram group](https://img.shields.io/badge/PerfMTK%20Telegram%20group-blue?style=flat-square&logo=telegram)](https://t.me/PerfMTK_chat) for support and suggestions
> [!CAUTION]
> Bootloops may occur in some custom ROMs, if this happens please delete the module folder from the recovery or constult https://topjohnwu.github.io/Magisk/faq.html#:~:text=I%20installed%20a%20module%20and%20it%20bootlooped%20my%20device

## License

This project is licensed under the [GPLv3 License](LICENSE).

## Disclaimer

Use this module at your own risk. While I strive for stability and performance, I cannot test all devices, so please report any bugs you find.
