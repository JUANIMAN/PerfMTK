# Changelog

## v12.0

### Changed

* Bumped version to **v12.0**
* Bug fixes and performance improvements

---

### Daemon

* Switched back to **STREAM_SOCKET** for IPC
* Updated **SELinux** policies to support stream socket communication
* Improved performance and efficiency
* Reduced excessive logging

---

### Notes

* **Breaking change:** The daemon now uses **STREAM_SOCKET** instead of DGRAM
* **LSPosed module update required:**
  The LSPosed module must be updated to use stream socket communication mechanism
* Additional improvements and optimizations were also applied to the **LSPosed module** for better compatibility and performance
