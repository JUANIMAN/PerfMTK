#!/system/bin/sh
MODDIR=${0%/*}

#################
# Initialization
#################

# Function to write to a file
write() {
  local file="$1"
  shift

  [ -f "$file" ] && echo "$@" > "$file"
}

# Tweak writeback
write /proc/sys/vm/dirty_writeback_centisecs 300

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

# wait for boot
resetprop -w sys.boot_completed 0

# fs tune
write /sys/block/mmcblk0/queue/iostats 0
write /sys/block/mmcblk0/queue/read_ahead_kb 512
write /sys/block/mmcblk0/queue/nr_requests 128
write /sys/block/sda/queue/iostats 0
write /sys/block/sda/queue/read_ahead_kb 128
write /sys/block/sda/queue/nr_requests 128
write /sys/block/sdb/queue/iostats 0
write /sys/block/sdb/queue/read_ahead_kb 128
write /sys/block/sdb/queue/nr_requests 128
write /sys/block/sdc/queue/iostats 0
write /sys/block/sdc/queue/read_ahead_kb 512
write /sys/block/sdc/queue/nr_requests 128
write /sys/block/dm-0/queue/read_ahead_kb 128
write /sys/block/dm-1/queue/read_ahead_kb 128
write /sys/block/dm-2/queue/read_ahead_kb 128
write /sys/block/dm-3/queue/read_ahead_kb 128
write /sys/block/dm-4/queue/read_ahead_kb 128
write /sys/block/dm-5/queue/read_ahead_kb 128

# setup tweaks
current_profile=$(getprop sys.perfmtk.current_profile)
"$MODDIR/system/bin/perfmtk" "$current_profile"

thermal_state=$(getprop sys.perfmtk.thermal_state)
"$MODDIR/system/bin/thermal_limit" "${thermal_state%?}"
