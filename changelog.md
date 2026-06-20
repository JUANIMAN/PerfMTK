# Changelog

## v14.3

### Changed

* **post-fs-data.sh**: revert memory management changes
* **Optimized daemon and perfmtk**: Bug fixes and performance improvements 
* **service.sh tuning updates**: Set the nr_request parameter to 64 to speed up the I/O response, and add checks to the scripts tweak 
* **Installer improvements**: Dynamically set Dalvik settings based on the total amount of RAM

### Added
* Add support for the new versions of KSU
* Add the new daemon settings: SCREEN_OFF_PROFILE and APP_DEBOUNCE_MS in app_profiles.conf

---

### Notes
* Update the LSPosed module to v5.0 to improve compatibility