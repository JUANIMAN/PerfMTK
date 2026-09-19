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

# Disable compaction proactiveness to eliminate background compaction stalls
write /proc/sys/vm/compaction_proactiveness 0

# Disable watermark boost to avoid unnecessary kswapd wakeups
write /proc/sys/vm/watermark_boost_factor 0

# Multi-Gen LRU (MGLRU)
write /sys/kernel/mm/lru_gen/enabled y

# zRAM tuning (page-cluster 3 and vma_ra_enabled true for fast batch decompression)
write /proc/sys/vm/page-cluster 3
write /proc/sys/vm/swappiness 100
write /sys/kernel/mm/swap/vma_ra_enabled true

# Scheduler PELT ramp/decay acceleration and RT uclamp baseline
write /proc/sys/kernel/sched_pelt_multiplier 4
write /proc/sys/kernel/sched_util_clamp_min_rt_default 0
