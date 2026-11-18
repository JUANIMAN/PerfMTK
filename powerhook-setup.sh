#!/system/bin/sh
# Shared setup helper for PerfMTK PowerHAL LD_PRELOAD hook overlay.
# Safe to run idempotently at post-fs-data boot or during live deployment.
MODDIR=${0%/*}

TARGET_DIR="/vendor/bin/hw"
TARGET_NAME="vendor.mediatek.hardware.mtkpower-service.mediatek"
TARGET_BIN="$TARGET_DIR/$TARGET_NAME"
TARGET_ORIG="$TARGET_DIR/$TARGET_NAME.orig"
HOOK_NAME="libperfmtk_powerhook.so"

STAGE_ROOT="/dev/.perfmtk_pwr"
STAGE_LOWER="$STAGE_ROOT/hw"
GATE_DIR="/data/vendor/powerhal"

ACTION="${1:-mount}"

is_overlay_mounted() {
  grep -q " $TARGET_DIR overlay " /proc/mounts 2>/dev/null
}

umount_powerhook_overlay() {
  local tries=0
  while is_overlay_mounted && [ "$tries" -lt 4 ]; do
    umount "$TARGET_DIR" 2>/dev/null || umount -l "$TARGET_DIR" 2>/dev/null || break
    tries=$((tries + 1))
  done
  rm -rf "$STAGE_LOWER" 2>/dev/null
}

read_selinux_ctx() {
  local path="$1"
  local fallback="$2"
  local ctx=""
  ctx="$(stat -c '%C' "$path" 2>/dev/null)"
  case "$ctx" in
    u:object_r:*) echo "$ctx"; return 0 ;;
  esac
  ctx="$(ls -dZ "$path" 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i ~ /^u:object_r:/) {print $i; exit}}')"
  case "$ctx" in
    u:object_r:*) echo "$ctx" ;;
    *) echo "$fallback" ;;
  esac
}

mount_powerhook_overlay() {
  # Unmount any existing overlay first so we always read the pure underlying vendor binary.
  if is_overlay_mounted || [ -e "$TARGET_ORIG" ]; then
    umount_powerhook_overlay
  fi

  [ -x "$TARGET_BIN" ] || return 0

  # Anti-loop fuse: refuse to snapshot a binary that already embeds PERFMTK_PWR_WRAPPED.
  if grep -q "PERFMTK_PWR_WRAPPED" "$TARGET_BIN" 2>/dev/null; then
    return 1
  fi

  local dir_ctx bin_ctx
  dir_ctx="$(read_selinux_ctx "$TARGET_DIR" "u:object_r:vendor_file:s0")"
  bin_ctx="$(read_selinux_ctx "$TARGET_BIN" "u:object_r:mtk_hal_power_exec:s0")"

  mkdir -p "$STAGE_ROOT" "$STAGE_LOWER" "$GATE_DIR" 2>/dev/null || true
  if [ -d "$GATE_DIR" ]; then
    rm -f "$STAGE_ROOT/.perfmtk_gate" 2>/dev/null || true
  fi
  chmod 0755 "$STAGE_ROOT" 2>/dev/null || true
  chcon "u:object_r:vendor_file:s0" "$STAGE_ROOT" 2>/dev/null || true

  rm -rf "$STAGE_LOWER"/* 2>/dev/null || true
  cp -f "$TARGET_BIN" "$STAGE_LOWER/$TARGET_NAME.orig" || return 1
  cp -f "$MODDIR/perfmtk_powerwrap" "$STAGE_LOWER/$TARGET_NAME" || return 1
  cp -f "$MODDIR/$HOOK_NAME" "$STAGE_LOWER/$HOOK_NAME" || return 1

  chown 0:2000 "$STAGE_LOWER" "$STAGE_LOWER/$TARGET_NAME.orig" "$STAGE_LOWER/$TARGET_NAME" 2>/dev/null || true
  chown 0:0 "$STAGE_LOWER/$HOOK_NAME" 2>/dev/null || true

  chmod 0751 "$STAGE_LOWER" || return 1
  chmod 0755 "$STAGE_LOWER/$TARGET_NAME.orig" "$STAGE_LOWER/$TARGET_NAME" || return 1
  chmod 0644 "$STAGE_LOWER/$HOOK_NAME" || return 1

  chcon "$dir_ctx" "$STAGE_LOWER" "$STAGE_LOWER/$HOOK_NAME" 2>/dev/null || true
  chcon "$bin_ctx" "$STAGE_LOWER/$TARGET_NAME.orig" "$STAGE_LOWER/$TARGET_NAME" 2>/dev/null || true

  if mount -t overlay overlay -o "lowerdir=$STAGE_LOWER:$TARGET_DIR" "$TARGET_DIR" 2>/dev/null; then
    return 0
  fi

  # Fallback for kernels requiring upperdir/workdir on overlayfs
  mkdir -p "$STAGE_ROOT/up" "$STAGE_ROOT/work" 2>/dev/null || true
  chmod 0751 "$STAGE_ROOT/up" "$STAGE_ROOT/work" 2>/dev/null || true
  chcon "$dir_ctx" "$STAGE_ROOT/up" "$STAGE_ROOT/work" 2>/dev/null || true
  mount -t overlay overlay -o "lowerdir=$STAGE_LOWER:$TARGET_DIR,upperdir=$STAGE_ROOT/up,workdir=$STAGE_ROOT/work" "$TARGET_DIR" 2>/dev/null
}

case "$ACTION" in
  mount|--mount)
    mount_powerhook_overlay
    ;;
  umount|unmount|--umount)
    umount_powerhook_overlay
    rm -rf "$STAGE_ROOT" 2>/dev/null || true
    ;;
  status|--status)
    if is_overlay_mounted && [ -x "$TARGET_ORIG" ] && [ -f "$TARGET_DIR/$HOOK_NAME" ]; then
      echo "mounted ($TARGET_DIR -> $STAGE_LOWER)"
      exit 0
    fi
    echo "unmounted"
    exit 1
    ;;
  *)
    echo "Usage: $0 [mount|umount|status]" >&2
    exit 2
    ;;
esac
