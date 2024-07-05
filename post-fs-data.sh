#!/system/bin/sh

#################
# Initialization
#################

# Function to write to a file
write() {
  local file="$1"
  shift

  [ -f "$file" ] && echo "$@" > "$file"
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

# Disable watermark boost
write /proc/sys/vm/watermark_boost_factor 0

# Disable compaction_proactiveness
write /proc/sys/vm/compaction_proactiveness 0

# multi-gen LRU
write /sys/kernel/mm/lru_gen/enabled y

# zram
write /sys/block/zram0/comp_algorithm lz4
write /proc/sys/vm/page-cluster 3
write /proc/sys/vm/swappiness 100
write /sys/kernel/mm/swap/vma_ra_enabled true

# kernel
write /proc/sys/kernel/sched_pelt_multiplier 4
write /proc/sys/kernel/sched_util_clamp_min_rt_default 0
