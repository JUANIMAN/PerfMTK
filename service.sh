#!/system/bin/sh
MODDIR=${0%/*}

#################
# Initialization
#################

# Function to write to a file
write() {
  local file="$1"
  shift

  if [ -f "$file" ]; then
    echo "$@" > "$file"
  fi
}

# scheduler tunables
write /proc/sys/kernel/sched_tunable_scaling 0
write /proc/sys/kernel/sched_latency_ns 10000000
write /proc/sys/kernel/sched_min_granularity_ns 1250000
write /proc/sys/kernel/sched_wakeup_granularity_ns 2000000
write /proc/sys/kernel/sched_child_runs_first 0

# Assign reasonable ceiling values for socket rcv/snd buffers.
write /proc/sys/net/core/rmem_max 262144
write /proc/sys/net/core/wmem_max 262144

# reflect fwmark from incoming packets onto generated replies
write /proc/sys/net/ipv4/fwmark_reflect 1
write /proc/sys/net/ipv6/fwmark_reflect 1

# set fwmark on accepted sockets
write /proc/sys/net/ipv4/tcp_fwmark_accept 1

# disable icmp redirects
write /proc/sys/net/ipv4/conf/all/accept_redirects 0
write /proc/sys/net/ipv6/conf/all/accept_redirects 0

# Don't slow network
write /proc/sys/net/ipv4/tcp_slow_start_after_idle 0

# set mtu probing and timestamps to 2
write /proc/sys/net/ipv4/tcp_mtu_probing 2
write /proc/sys/net/ipv4/tcp_timestamps 2

# enable tcp fastopen
write /proc/sys/net/ipv4/tcp_fastopen 3

# set tcp congestion control
if grep bbr /proc/sys/net/ipv4/tcp_available_congestion_control; then
  write /proc/sys/net/ipv4/tcp_congestion_control bbr
elif grep westwood /proc/sys/net/ipv4/tcp_available_congestion_control; then
  write /proc/sys/net/ipv4/tcp_congestion_control westwood
else
  write /proc/sys/net/ipv4/tcp_congestion_control cubic
fi

# wait for boot
resetprop -w sys.boot_completed 0

# Memory management
write /proc/sys/vm/overcommit_memory 1
write /proc/sys/vm/min_free_order_shift 4

# Tweak writeback
write /proc/sys/vm/dirty_writeback_centisecs 300

# enable ppm
write /proc/ppm/enabled 1

# Tweak PPM
DEVICE=$(getprop ro.product.device)
if [ "$DEVICE" = begonia ] || [ "$DEVICE" = begoniain ]; then
  write /proc/ppm/policy_status 3 0
  write /proc/ppm/policy_status 4 0
  write /proc/ppm/policy_status 5 0
else
  write /proc/ppm/policy_status 2 0
  write /proc/ppm/policy_status 3 0
  write /proc/ppm/policy_status 4 0
fi

# cluster fix
if [ -d /sys/devices/system/cpu/cpufreq/policy0 ] && [ -d /sys/devices/system/cpu/cpufreq/policy4 ]; then
  if [ -d /sys/devices/system/cpu/cpufreq/policy7 ]; then
    write /proc/ppm/policy/ut_fix_core_num 4 3 1
  else
    write /proc/ppm/policy/ut_fix_core_num 4 4
  fi
elif [ -d /sys/devices/system/cpu/cpufreq/policy0 ] && [ -d /sys/devices/system/cpu/cpufreq/policy6 ]; then
  write /proc/ppm/policy/ut_fix_core_num 6 2
fi

# CPU freq power mode
write /proc/cpufreq/cpufreq_power_mode 3

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

# disable fsync
write /sys/module/sync/parameters/fsync_enabled N

# setup tweaks
current_profile=$(getprop sys.perfmtk.current_profile)
"$MODDIR/system/bin/$current_profile"

thermal_state=$(getprop sys.perfmtk.thermal_throttling)
"$MODDIR/system/bin/thermal_limit" "$thermal_state"
