#!/system/bin/sh

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

# update cpus for cpuset cgroup
if [ -d /sys/devices/system/cpu/cpufreq/policy6 ]; then
  write /dev/cpuset/foreground/cpus 0-7
  write /dev/cpuset/foreground/boost/cpus 6-7
  write /dev/cpuset/background/cpus 0-5
  write /dev/cpuset/system-background/cpus 0-5
  write /dev/cpuset/top-app/cpus 0-7
  write /dev/cpuset/top-app/boost/cpus 6-7
  write /dev/cpuset/ui/cpus 6-7
else
  write /dev/cpuset/foreground/cpus 0-7
  write /dev/cpuset/foreground/boost/cpus 4-7
  write /dev/cpuset/background/cpus 0-3
  write /dev/cpuset/system-background/cpus 0-3
  write /dev/cpuset/top-app/cpus 0-7
  write /dev/cpuset/top-app/boost/cpus 4-7
  write /dev/cpuset/ui/cpus 4-7
fi

# Disable compaction proactiveness
write /proc/sys/vm/compaction_proactiveness 0

# Disable watermark boost
write /proc/sys/vm/watermark_boost_factor 0

# multi-gen LRU
write /sys/kernel/mm/lru_gen/enabled y

# zram
write /proc/sys/vm/page-cluster 3
write /proc/sys/vm/swappiness 100
write /sys/kernel/mm/swap/vma_ra_enabled true

# kernel
write /proc/sys/kernel/sched_pelt_multiplier 4
write /proc/sys/kernel/sched_util_clamp_min_rt_default 0
