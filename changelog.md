# Changelog

## v11.1

### Added

* Backup and restore logic for profile configurations.
* Cache system to optimize frequent read operations.
* Persistent logging system with severity levels: INFO, WARN, ERROR.
* Extended CPU information in device configuration.
* New command-line options:

  * `--backup`
  * `--restore`
  * `--status`
  * `--validate`
* Detailed logging for all daemon operations.
* Reduced overhead by minimizing subshell usage and unnecessary pipes.
* Improved trap handling and process cleanup.

---

### Changed

* Updated version to **v11.1**.
* Updated execution path for `perfmtk_daemon`.
* Improved overall performance, logging, and profile management.

---

### Daemon Changes

* Switched IPC socket implementation from **STREAM** to **DGRAM**.
* Updated SELinux policy rules to allow DGRAM socket communication.
* Improved core logic for application switching and profile application.
* Optimized string processing routines.

---

### Fixed

* Multiple internal daemon bugs.
* Edge cases in profile application and app context switching.

---

### Notes

* **Important:** The daemon now uses a **DGRAM-based, message-oriented IPC model**.
* **LSPosed module update required:**
  The LSPosed module must be updated to use the new DGRAM socket communication mechanism.
  Older versions expecting STREAM-based communication will no longer be compatible.
