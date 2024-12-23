# PerfMTK

A Magisk module for MediaTek devices with Mali GPUs.

![GitHub all releases](https://img.shields.io/github/downloads/JUANIMAN/PerfMTK/total)

## Overview

PerfMTK is a powerful Magisk module designed to optimize performance and power efficiency on MediaTek devices. It offers granular control over various system aspects.

## Features

- Specific adjustments for MediaTek SOCs
- Support for various CPU configurations (dual-cluster, tri-cluster)
- Modes: Powersave, Balanced, and Performance
- Dynamic adjustment of CPU and GPU frequencies
- CPU and GPU governor configuration
- Option to enable/disable thermal limitations
- zram and swap adjustments
- I/O parameter optimization for UFS storage
- Kernel task scheduler adjustments
- Control group (cgroups) optimization for different types of applications
- Adjustments to improve gaming performance
- Settings to improve energy efficiency, especially in powersave mode

## Installation

1. Ensure you have Magisk installed on your MediaTek device.
2. Download the latest PerfMTK zip file from the releases page.
3. Flash the zip file through Magisk Manager.
4. Reboot your device.

## Usage

### Via Terminal (e.g., Termux)

Just type `su -c perfmtk` for menu

Or change performance profiles manually:
```
su -c perfmtk performance
su -c perfmtk balanced
su -c perfmtk powersave
su -c perfmtk powersave+
```

To control thermal limitations:
```
su -c thermal_limit enable
su -c thermal_limit disable
```

### Via PerfMTK Manager App

1. Open the [PerfMTK Manager app](https://github.com/JUANIMAN/PerfMTK-Manager).
2. Simply select the desired performance profile.
3. Optionally, thermal limitations on/off.

Download: [Here](https://github.com/JUANIMAN/PerfMTK-Manager/releases/latest)

## Compatibility

- PerfMTK is designed for MediaTek devices with Mali GPUs.
- It's compatible with various Android versions (9 or higher).
- Do not use on devices with kernel versions lower than 4.14.x
- Recommended to use magisk 27 or higher

## Troubleshooting

If you encounter any issues:
1. Ensure you're using the latest version of PerfMTK.
2. Check if your device is supported.
3. Try rebooting your device after making changes.
4. If problems persist, please report the issue in the GitHub issues section with detailed information about your device and the problem you're experiencing.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the [GPLv3](LICENSE).

## Disclaimer

Use this module at your own risk. While I strive for stability and performance, I cannot test all devices, so please report any bugs.
