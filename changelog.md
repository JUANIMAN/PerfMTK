# Changelog

- Improve daemon efficiency with adaptive monitoring, inotify, and concurrency optimizations
- Replaced shell command pipeline with native parsing, reducing overhead and improving reliability. Also refined screen state logic.
- The config file app_profiles.conf is now stored in /data/local to prevent it from being deleted during module updates. It will only be removed when the module is fully uninstalled.