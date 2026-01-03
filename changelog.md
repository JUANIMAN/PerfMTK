# Changelog

### Added
- **Automatic Hardware Detection** for MediaTek (MTK) devices
- **Customizable Profile Configurations**: Profile configurations now editable via `.conf` files
- **Persistent Configuration Storage**:
  - Device config: `/data/adb/modules/perfmtk/config/device.conf`
  - Profile configs: `/data/adb/modules/perfmtk/config/profiles/*.conf`


#### New CLI commands:
```
- perfmtk --detect         # Detect device hardware
- perfmtk --generate       # Generate default profiles
- perfmtk --list           # List available profiles
- perfmtk --info           # Show device hardware info
- perfmtk --edit <profile> # Edit profile configuration
- perfmtk <custom_profile> # Apply custom profile
```

### PerfMTK Daemon
- **IPC via Unix Domain Socket**: Event-driven architecture using abstract Unix socket for improved battery efficiency
  - Receives screen on/off state changes
  - Receives foreground application package updates
  - Integrated with LSPosed hook module (optional but recommended for best performance)
- **Automatic Fallback**: Uses legacy `dumpsys power` and `dumpsys window` queries when LSPosed is not installed
- **SELinux Policy**: Added proper policy to permit `system_server` → `perfmtk_daemon` socket connections

### Other changes
- Improved installation and boot scripts
- Replaced brittle, line-based cleanup logic with marker-range operations
- Replaced hard-coded I/O tuning in `service.sh` with dynamic I/O tuning
