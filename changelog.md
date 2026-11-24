# Changelog

## v17.3

- **PowerHook Overlay (AIDL & HIDL)**: Real-time MediaTek PowerHAL interception that prevents OEM frequency caps, thermal FPS throttling, and unwanted background interference during gaming.
- **Next-Gen RenderBooster & Low-Latency Scheduling**: Modular thread routing with isolated Prime/Big/VIP cpusets and real-time GPU/display sync for faster touch response, steadier 120 FPS, and fewer micro-stutters.
- **Smart Fast Charge, Hardware Bypass & Battery Care**: Clear separation between thermal fast-charge unthrottling and true hardware battery bypass, customizable charging cut-off limit (75%–90%), and real-time battery telemetry (current, voltage, power, cycles, and health).
- **Zero-Copy Telemetry & Profile Management**: Ultra-lightweight shared-memory telemetry for PerfMTK Manager, automatic timestamped profile backups with management/deletion, and a fully device-agnostic profile generator (`perfmtk -g`).
- **Thermal, GPU & Memory Calibration**: Cooler sustained gaming temperatures, low-thrash memory presets for `<= 8 GB` RAM devices, and smoother CPU/GPU scaling with reduced frame-time jitter.
- **Expanded MediaTek Compatibility & Installer Hardening**: Dynamic multi-SoC support across Dimensity (9400/9300 All-Big, 8300/8200/9200 Tri-Cluster, 7200/7050 Dual-Cluster) and Helio G-series (G99/G96/G90T), plus safer daemon restarts, touch-immune installer prompts, and Android 14–16 OEM fixes.

### Notes

Please run `su -c perfmtk -d` and `su -c perfmtk -g` to regenerate hardware configurations and profiles.
