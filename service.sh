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

# Ensure initial hardware configs exist and are non-corrupt
if [ ! -s "$MODDIR/config/device.conf" ] || ! grep -q "POLICY_0_PATH" "$MODDIR/config/device.conf" 2>/dev/null; then
  "$MODDIR/system/bin/perfmtk" -d >/dev/null 2>&1
  "$MODDIR/system/bin/perfmtk" -g >/dev/null 2>&1
fi

# Ensure perfmtk & thermal_limit CLI symlinks are accessible in root PATH
for bin_dir in /data/adb/ksu/bin /data/adb/ap/bin /data/adb/magisk; do
  if [ -d "$bin_dir" ]; then
    ln -sf "$MODDIR/system/bin/perfmtk" "$bin_dir/perfmtk" 2>/dev/null
    [ -f "$MODDIR/system/bin/thermal_limit" ] && \
      ln -sf "$MODDIR/system/bin/thermal_limit" "$bin_dir/thermal_limit" 2>/dev/null
  fi
done

# Single-instance watchdog: terminate previous instance cleanly and wait for exit
if pidof perfmtkd >/dev/null 2>&1; then
  killall perfmtkd 2>/dev/null
  waited=0
  while pidof perfmtkd >/dev/null 2>&1 && [ "$waited" -lt 30 ]; do
    sleep 0.1
    waited=$((waited + 1))
  done
  if pidof perfmtkd >/dev/null 2>&1; then
    pkill -9 perfmtkd 2>/dev/null
    sleep 0.2
  fi
fi

# Start native background daemon first (automatically initializes drivers & applies default_profile)
DAEMON_BIN=""
if [ -f "$MODDIR/system/bin/perfmtkd" ]; then
  DAEMON_BIN="$MODDIR/system/bin/perfmtkd"
elif [ -f "$MODDIR/perfmtkd" ]; then
  DAEMON_BIN="$MODDIR/perfmtkd"
fi

if [ -n "$DAEMON_BIN" ]; then
  log -t PerfMTK "Starting Native PerfMTK Daemon from $DAEMON_BIN"
  "$DAEMON_BIN" >/dev/null 2>&1 &
fi

# Apply persisted thermal state via IPC if explicitly disabled
thermal_state=$(getprop sys.perfmtk.thermal_state)
if [ "$thermal_state" = "disabled" ]; then
  waited=0
  while ! "$MODDIR/system/bin/perfmtk" -s >/dev/null 2>&1 && [ "$waited" -lt 30 ]; do
    sleep 0.1
    waited=$((waited + 1))
  done
  "$MODDIR/system/bin/perfmtk" thermal disabled >/dev/null 2>&1
fi

