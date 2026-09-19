#!/system/bin/sh
MODDIR=${0%/*}

#################
# Initialization
#################

# Function to write to a file safely
write() {
  local file="$1"
  shift

  [ ! -e "$file" ] && return 1

  echo "$@" > "$file" 2>/dev/null && return 0

  local original_perms=$(stat -c '%a' "$file" 2>/dev/null)
  if [ -n "$original_perms" ]; then
    chmod u+rw "$file" 2>/dev/null
    echo "$@" > "$file" 2>/dev/null
    local result=$?
    chmod "$original_perms" "$file" 2>/dev/null
    return $result
  fi

  return 1
}

for policy in /sys/devices/system/cpu/cpufreq/policy*; do
  chown system:system "$policy/scaling_governor" 2>/dev/null
  chmod 0660 "$policy/scaling_governor" 2>/dev/null
done

# ---------------------------------------------------------
# BEGIN_OPTIMIZATIONS_PPM
# ---------------------------------------------------------
# PPM Tweaks (Legacy MediaTek platforms)
if [ -d /proc/ppm ]; then
  write /proc/ppm/enabled 1

  DEVICE=$(getprop ro.product.device)
  case "$DEVICE" in
    begonia | begoniain)
      for i in 3 4 5; do
        write /proc/ppm/policy_status $i 0
      done
      ;;
    *)
      for i in 2 3 4; do
        write /proc/ppm/policy_status $i 0
      done
      ;;
  esac

  if [ -d /sys/devices/system/cpu/cpufreq/policy0 ]; then
    if [ -d /sys/devices/system/cpu/cpufreq/policy4 ]; then
      if [ -d /sys/devices/system/cpu/cpufreq/policy7 ]; then
        write /proc/ppm/policy/ut_fix_core_num 4 3 1
      else
        write /proc/ppm/policy/ut_fix_core_num 4 4
      fi
    elif [ -d /sys/devices/system/cpu/cpufreq/policy6 ]; then
      write /proc/ppm/policy/ut_fix_core_num 6 2
    fi
  fi
fi
# ---------------------------------------------------------
# END_OPTIMIZATIONS_PPM
# ---------------------------------------------------------

# Wait for boot completion
resetprop -w sys.boot_completed 0

# Disable HyperOS aggressive IMR / MMMS background app killer
resetprop -n persist.sys.mms.use_integrated_memory_reclaim false
resetprop -n persist.sys.imr.memfree.limit 0
resetprop -n persist.sys.mmms.switch false

# ---------------------------------------------------------
# BEGIN_OPTIMIZATIONS_IO
# ---------------------------------------------------------
# Block queue readahead and request depth tuning
for queue in /sys/block/*/queue; do
  device_name=$(basename "$(dirname "$queue")")

  case "$device_name" in
    loop*|ram*|zram*) continue ;;
  esac

  case "$device_name" in
    mmcblk*|sd*)
      write "$queue/read_ahead_kb" 256
      write "$queue/nr_requests" 64
      ;;
    *)
      write "$queue/read_ahead_kb" 128
      write "$queue/nr_requests" 128
      ;;
  esac
done
# ---------------------------------------------------------
# END_OPTIMIZATIONS_IO
# ---------------------------------------------------------

# Ensure initial hardware configs exist
if [ ! -f "$MODDIR/config/device.conf" ]; then
  "$MODDIR/system/bin/perfmtk" -d >/dev/null 2>&1
  "$MODDIR/system/bin/perfmtk" -g >/dev/null 2>&1
fi

# Apply current profile if configured
current_profile=$(getprop sys.perfmtk.current_profile)
if [ -n "$current_profile" ]; then
  "$MODDIR/system/bin/perfmtk" "$current_profile" >/dev/null 2>&1
fi

# Apply thermal state if configured
thermal_state=$(getprop sys.perfmtk.thermal_state)
if [ -n "$thermal_state" ]; then
  "$MODDIR/system/bin/perfmtk" thermal "$thermal_state" >/dev/null 2>&1
fi

# Ensure perfmtk and thermal_limit are accessible in root PATH
for bin_dir in /data/adb/ksu/bin /data/adb/ap/bin /data/adb/magisk; do
  if [ -d "$bin_dir" ]; then
    ln -sf "$MODDIR/system/bin/perfmtk" "$bin_dir/perfmtk" 2>/dev/null
    ln -sf "$MODDIR/system/bin/thermal_limit" "$bin_dir/thermal_limit" 2>/dev/null
  fi
done

# Single-instance watchdog: terminate previous instance if running
killall perfmtkd 2>/dev/null
sleep 0.5

# Start native background daemon with persistent auto-recovery watchdog
if [ -f "$MODDIR/perfmtkd" ]; then
  log -t PerfMTK "Starting Native PerfMTK Daemon from $MODDIR/perfmtkd"
  "$MODDIR/perfmtkd" &
fi
