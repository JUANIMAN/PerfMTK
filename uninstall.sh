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
resetprop --delete sys.perfmtk.display_fps 2>/dev/null
for prop in \
  persist.sys.mms.use_integrated_memory_reclaim \
  persist.sys.imr.memfree.limit \
  persist.sys.mmms.switch; do
  resetprop -p -d "$prop" 2>/dev/null || true
done
rm -rf /data/adb/perfmtk_backup 2>/dev/null

# Clean up PerfMTK PowerHAL overlay and shared gate
if grep -q " /vendor/bin/hw overlay " /proc/mounts 2>/dev/null; then
  umount /vendor/bin/hw 2>/dev/null || umount -l /vendor/bin/hw 2>/dev/null || true
fi
rm -f /data/vendor/powerhal/.perfmtk_gate
rm -rf /dev/.perfmtk_pwr
