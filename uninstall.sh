#!/system/bin/sh

# Terminate running PerfMTK Daemon
killall perfmtkd 2>/dev/null
pkill -9 perfmtkd 2>/dev/null

# Clean up symlinks in root PATH
rm -f /data/adb/ksu/bin/perfmtk /data/adb/ksu/bin/thermal_limit 2>/dev/null
rm -f /data/adb/ap/bin/perfmtk /data/adb/ap/bin/thermal_limit 2>/dev/null
rm -f /data/adb/magisk/perfmtk /data/adb/magisk/thermal_limit 2>/dev/null

# Clean up legacy configs / transient files
rm -f /data/local/app_profiles.conf 2>/dev/null
rm -f /data/local/tmp/perfmtk* 2>/dev/null
rm -f /dev/socket/perfmtkd.sock 2>/dev/null

# Reset properties
resetprop --delete sys.perfmtk.current_profile 2>/dev/null
resetprop --delete sys.perfmtk.thermal_state 2>/dev/null
