#!/system/bin/sh

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

# Update cpus for cpuset cgroups based on CPU topology
total_cpus=$(ls -d /sys/devices/system/cpu/cpu[0-9]* 2>/dev/null | wc -l)
[ -z "$total_cpus" ] || [ "$total_cpus" -le 0 ] && total_cpus=8
all_cpus="0-$((total_cpus - 1))"

if [ "$total_cpus" -ge 8 ]; then
  if [ -d /sys/devices/system/cpu/cpufreq/policy7 ]; then
    # Tri-cluster (4 Little + 3 Mid + 1 Prime, e.g. Dimensity 8300 / 8200 / 9200)
    write /dev/cpuset/foreground/cpus 0-7
    write /dev/cpuset/foreground/boost/cpus 4-7
    write /dev/cpuset/background/cpus 0-3
    write /dev/cpuset/system-background/cpus 0-3
    write /dev/cpuset/top-app/cpus 0-7
    write /dev/cpuset/top-app/boost/cpus 4-7
    write /dev/cpuset/ui/cpus 4-7
  elif [ -d /sys/devices/system/cpu/cpufreq/policy6 ]; then
    # Dual-cluster 6+2 (6 Little + 2 Big, e.g. Helio G85 / G90T / G99)
    write /dev/cpuset/foreground/cpus 0-7
    write /dev/cpuset/foreground/boost/cpus 6-7
    write /dev/cpuset/background/cpus 0-5
    write /dev/cpuset/system-background/cpus 0-5
    write /dev/cpuset/top-app/cpus 0-7
    write /dev/cpuset/top-app/boost/cpus 6-7
    write /dev/cpuset/ui/cpus 6-7
  else
    # Dual-cluster 4+4 (4 Little + 4 Big, e.g. Dimensity 8400 / 9400)
    write /dev/cpuset/foreground/cpus 0-7
    write /dev/cpuset/foreground/boost/cpus 4-7
    write /dev/cpuset/background/cpus 0-3
    write /dev/cpuset/system-background/cpus 0-3
    write /dev/cpuset/top-app/cpus 0-7
    write /dev/cpuset/top-app/boost/cpus 4-7
    write /dev/cpuset/ui/cpus 4-7
  fi
elif [ "$total_cpus" -gt 4 ]; then
  half_core=$((total_cpus / 2))
  write /dev/cpuset/foreground/cpus "$all_cpus"
  write /dev/cpuset/foreground/boost/cpus "$half_core-$((total_cpus - 1))"
  write /dev/cpuset/background/cpus "0-$((half_core - 1))"
  write /dev/cpuset/system-background/cpus "0-$((half_core - 1))"
  write /dev/cpuset/top-app/cpus "$all_cpus"
  write /dev/cpuset/top-app/boost/cpus "$half_core-$((total_cpus - 1))"
  write /dev/cpuset/ui/cpus "$half_core-$((total_cpus - 1))"
else
  write /dev/cpuset/foreground/cpus "$all_cpus"
  write /dev/cpuset/foreground/boost/cpus "2-$((total_cpus - 1))"
  write /dev/cpuset/background/cpus "0-1"
  write /dev/cpuset/system-background/cpus "0-1"
  write /dev/cpuset/top-app/cpus "$all_cpus"
  write /dev/cpuset/top-app/boost/cpus "$all_cpus"
  write /dev/cpuset/ui/cpus "$all_cpus"
fi

# Disable compaction proactiveness to eliminate background compaction stalls
write /proc/sys/vm/compaction_proactiveness 0

# Disable watermark boost to avoid unnecessary kswapd wakeups
write /proc/sys/vm/watermark_boost_factor 0

# Multi-Gen LRU (MGLRU)
write /sys/kernel/mm/lru_gen/enabled y

# zRAM tuning (page-cluster 0 for zero-latency single-page compressed swap and vma_ra_enabled true)
write /proc/sys/vm/page-cluster 0
write /proc/sys/vm/swappiness 100
write /sys/kernel/mm/swap/vma_ra_enabled true

# Scheduler PELT ramp/decay acceleration and RT uclamp baseline
write /proc/sys/kernel/sched_pelt_multiplier 4
write /proc/sys/kernel/sched_util_clamp_min_rt_default 0

# Low-latency TCP & network socket optimization
write /proc/sys/net/ipv4/tcp_fastopen 3
write /proc/sys/net/ipv4/tcp_autocorking 0
write /proc/sys/net/ipv4/tcp_low_latency 1
write /proc/sys/net/ipv4/tcp_tw_reuse 1
write /proc/sys/net/core/netdev_max_backlog 5000

# HyperOS Display & Idle Refresh Rate Vendor Overrides (Option B)
resetprop_bin="resetprop"
[ -f /data/adb/ksu/bin/resetprop ] && resetprop_bin="/data/adb/ksu/bin/resetprop"
[ -f /data/adb/ap/bin/resetprop ] && resetprop_bin="/data/adb/ap/bin/resetprop"
[ -f /data/adb/magisk/resetprop ] && resetprop_bin="/data/adb/magisk/resetprop"

$resetprop_bin -n ro.vendor.disable_idle_fps.threshold 1 2>/dev/null
$resetprop_bin -n persist.vendor.disable_idle_fps.threshold 1 2>/dev/null
$resetprop_bin -n persist.vendor.disable_idle_fps 0 2>/dev/null
$resetprop_bin -n debug.sf.set_touch_timer_ms 1000 2>/dev/null
$resetprop_bin -n ro.surface_flinger.set_touch_timer_ms 1000 2>/dev/null
