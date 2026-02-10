#!/system/bin/sh
MODDIR=${0%/*}

#################
# Initialization
#################

# Function to write to a file
write() {
  local file="$1"
  shift

  # Check if the file exists
  [ ! -e "$file" ] && return 1

  # Try to write directly
  echo "$@" > "$file" 2>/dev/null && return 0

  # If it fails, try with temporary permissions
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

# Tweak writeback
write /proc/sys/vm/dirty_writeback_centisecs 300

# ---------------------------------------------------------
# BEGIN_OPTIMIZATIONS_PPM
# ---------------------------------------------------------
# PPM Tweaks
if [ -d /proc/ppm ]; then
  # Enable PPM
  write /proc/ppm/enabled 1

  # Disable PPM
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

  # cluster fix
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

# wait for boot
resetprop -w sys.boot_completed 0

# ---------------------------------------------------------
# BEGIN_OPTIMIZATIONS_IO
# ---------------------------------------------------------
# fs tune
for queue in /sys/block/*/queue; do
  device_name=$(basename "$(dirname "$queue")")

  case "$device_name" in
    loop*|ram*|zram*) continue ;;
  esac

  write "$queue/iostats" 0

  case "$device_name" in
    mmcblk*)
      write "$queue/read_ahead_kb" 512
      ;;
    sd*)
      write "$queue/read_ahead_kb" 512
      ;;
    *)
      write "$queue/read_ahead_kb" 128
      ;;
  esac

  write "$queue/nr_requests" 128
done
# ---------------------------------------------------------
# END_OPTIMIZATIONS_IO
# ---------------------------------------------------------

# setup tweaks
current_profile=$(getprop sys.perfmtk.current_profile)
"$MODDIR/system/bin/perfmtk" "$current_profile"

thermal_state=$(getprop sys.perfmtk.thermal_state)
"$MODDIR/system/bin/thermal_limit" "${thermal_state%?}"

sleep 2

# Start daemon
if [ -f "$MODDIR/perfmtk_daemon" ]; then
  log -t PerfMTKDaemon "Starting Daemon"
  "$MODDIR/perfmtk_daemon"
fi
