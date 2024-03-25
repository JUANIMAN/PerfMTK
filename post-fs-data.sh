#!/system/bin/sh

# write function
write() {
  local file_path="$1"
  shift

  if [ -f "$file_path" ]; then
    echo "$@" >"$file_path"
  fi
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

# zram
write /proc/sys/vm/page-cluster 3
write /proc/sys/vm/swappiness 100
write /sys/kernel/mm/swap/vma_ra_enabled false
