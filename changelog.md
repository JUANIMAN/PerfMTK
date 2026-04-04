# Changelog

## v13.0

### Changed

* **post-fs-data.sh**: optimized memory handling (swap/zram) for lower latency and better responsiveness
* **Optimized daemon**: reduced overhead, asynchronous logging, and more efficient execution model
* **Optimized perfmtk**: removed reliance on external commands in parsing, significantly reducing profile application time
* **service.sh tuning updates**: improved I/O parameters for better stability and responsiveness, and remove dirty_writeback_centisecs tweak 
* **Installer improvements**: cleaner flow, reduced complexity, and more reliable execution
---

### Notes
* Update the LSPosed module to v4.0 to improve compatibility