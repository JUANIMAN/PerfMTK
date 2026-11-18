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

# Disable compaction proactiveness to eliminate background compaction stalls
write /proc/sys/vm/compaction_proactiveness 0

# Disable watermark boost to avoid unnecessary kswapd wakeups
write /proc/sys/vm/watermark_boost_factor 0

# Multi-Gen LRU (MGLRU)
write /sys/kernel/mm/lru_gen/enabled 0x0003

# zRAM tuning (page-cluster 0 for zero-latency single-page compressed swap and vma_ra_enabled true)
write /proc/sys/vm/page-cluster 0
write /proc/sys/vm/swappiness 100
write /sys/kernel/mm/swap/vma_ra_enabled true

# Preserved stock OEM PELT multiplier (HyperOS 2 defaults to 4, left untouched)
# write /proc/sys/kernel/sched_pelt_multiplier 4
write /proc/sys/kernel/sched_util_clamp_min_rt_default 0

# Low-latency TCP & network socket optimization
write /proc/sys/net/ipv4/tcp_fastopen 3
write /proc/sys/net/ipv4/tcp_autocorking 0
write /proc/sys/net/ipv4/tcp_low_latency 1
write /proc/sys/net/ipv4/tcp_tw_reuse 1
write /proc/sys/net/core/netdev_max_backlog 5000

# PerfMTK PowerHAL LD_PRELOAD overlay
if [ -f "$MODDIR/powerhook-setup.sh" ]; then
  sh "$MODDIR/powerhook-setup.sh" mount 2>/dev/null || true
fi
