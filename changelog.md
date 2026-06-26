# Changelog

## v15.0

### What's new

* **Advanced CPU Tuning (Multi-Policy Support)**: You can now customize speed behaviors (governors and responsiveness limits) independently for each CPU cluster (e.g., performance and efficiency cores), allowing for highly optimized custom profiles.
* **Better GPU Compatibility**: Improved hardware detection for newer MediaTek devices, ensuring the graphics processor frequencies are detected and managed correctly even on custom kernels.

### Improvements

* **Rock-solid profile validation**: The engine now performs a thorough self-diagnostic scan on your profile settings before applying them, preventing invalid configurations from causing system instability.
* **Android System Reliability**: Cleaned up internal commands to use native Android shells rather than external utilities, reducing resource usage and ensuring smooth operation across all Android versions.
