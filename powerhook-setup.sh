#!/system/bin/sh
# Shared setup helper for PerfMTK PowerHAL LD_PRELOAD hook overlay.
# Safe to run idempotently at post-fs-data boot or during live deployment.
MODDIR=${0%/*}

TARGET_DIR="/vendor/bin/hw"
# MediaTek AIDL PowerHAL candidates (Android 14+).
TARGET_CANDIDATES="
vendor.mediatek.hardware.mtkpower-service.mediatek
vendor.mediatek.hardware.mtkpower-service
"
TARGET_NAME=""
TARGET_BIN=""
TARGET_ORIG=""
HOOK_NAME="libperfmtk_powerhook.so"

STAGE_ROOT="/dev/.perfmtk_pwr"
STAGE_LOWER="$STAGE_ROOT/hw"
STAGE_TARGET_FILE="$STAGE_ROOT/target_orig"
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
  rm -f "$STAGE_TARGET_FILE" 2>/dev/null
}

has_any_orig_binary() {
  local cand
  for cand in $TARGET_CANDIDATES; do
    [ -e "$TARGET_DIR/$cand.orig" ] && return 0
  done
  return 1
}

detect_target_name() {
  local cand
  for cand in $TARGET_CANDIDATES; do
    [ -x "$TARGET_DIR/$cand" ] && { echo "$cand"; return 0; }
  done
  return 1
}

detect_mounted_orig() {
  local recorded="" cand
  if [ -r "$STAGE_TARGET_FILE" ]; then
    IFS= read -r recorded < "$STAGE_TARGET_FILE" 2>/dev/null
    if [ -n "$recorded" ]; then
      echo "$recorded"
      return 0
    fi
  fi
  for cand in $TARGET_CANDIDATES; do
    [ -e "$TARGET_DIR/$cand.orig" ] && { echo "$TARGET_DIR/$cand.orig"; return 0; }
  done
  return 1
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
  # Guard: only mount on Android 14+ (SDK >= 34) with a tested AIDL PowerHAL binary.
  local sdk
  sdk="$(getprop ro.build.version.sdk 2>/dev/null | tr -cd '[:digit:]')"
  [ -n "$sdk" ] && [ "$sdk" -ge 34 ] || return 0

  # Unmount any existing overlay first so we always read the pure underlying vendor binary.
  if is_overlay_mounted || has_any_orig_binary; then
    umount_powerhook_overlay
  fi

  TARGET_NAME="$(detect_target_name)"
  [ -n "$TARGET_NAME" ] || return 0
  TARGET_BIN="$TARGET_DIR/$TARGET_NAME"
  TARGET_ORIG="$TARGET_DIR/$TARGET_NAME.orig"

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

  # Record resolved .orig path for perfmtk_powerwrap (POWERHOOK_ORIG_PATH_FILE).
  printf '%s\n' "$TARGET_ORIG" > "$STAGE_TARGET_FILE" 2>/dev/null || true
  chmod 0644 "$STAGE_TARGET_FILE" 2>/dev/null || true
  chcon "u:object_r:vendor_file:s0" "$STAGE_TARGET_FILE" 2>/dev/null || true

  if mount -t overlay overlay -o "lowerdir=$STAGE_LOWER:$TARGET_DIR" "$TARGET_DIR" 2>/dev/null; then
    return 0
  fi

  # Fallback for kernels requiring upperdir/workdir on overlayfs
  mkdir -p "$STAGE_ROOT/up" "$STAGE_ROOT/work" 2>/dev/null || true
  chmod 0751 "$STAGE_ROOT/up" "$STAGE_ROOT/work" 2>/dev/null || true
  chcon "$dir_ctx" "$STAGE_ROOT/up" "$STAGE_ROOT/work" 2>/dev/null || true
  if mount -t overlay overlay -o "lowerdir=$STAGE_LOWER:$TARGET_DIR,upperdir=$STAGE_ROOT/up,workdir=$STAGE_ROOT/work" "$TARGET_DIR" 2>/dev/null; then
    return 0
  fi

  rm -f "$STAGE_TARGET_FILE" 2>/dev/null || true
  return 1
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
    TARGET_ORIG="$(detect_mounted_orig)"
    if is_overlay_mounted && [ -n "$TARGET_ORIG" ] && [ -x "$TARGET_ORIG" ] && [ -f "$TARGET_DIR/$HOOK_NAME" ]; then
      echo "mounted ($TARGET_DIR -> $STAGE_LOWER, orig=$TARGET_ORIG)"
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
