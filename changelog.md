# Changelog

### Added
- **PerfMTK Daemon**: Added a daemon that monitors foreground applications and applies the corresponding performance profile from the configuration file.
- Added `app_profiles.conf` to define energy profiles for applications, with a default global profile when no application is in the foreground.
- Updated `service.sh` to start the PerfMTK Daemon if available, with a log message for daemon startup.
- **Customize Script**: 
  - Added detailed descriptions for each configuration option in `customize.sh`.
  - Included more device information (RAM, SOC, etc.) at the beginning of the script.
  - Added more informative messages during each installation step.
  - Improved the presentation of the selection options.
  - Added an option to install the daemon during the setup process.

### Changed
- **Compatibility**: Made scripts compatible with 32-bit systems.
- **Keycheck**: Recompiled the `keycheck` binary for compatibility.
