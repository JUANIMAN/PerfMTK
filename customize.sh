SKIPUNZIP=1

# Module information
MODVER=$(grep_prop version "$TMPDIR/module.prop")
MODAUTH=$(grep_prop author "$TMPDIR/module.prop")

# System information
LANG=$(settings get system system_locales)
BRAND=$(getprop ro.product.vendor.brand)
[ -z "$BRAND" ] && BRAND=$(getprop ro.product.brand)
SOC=$(getprop ro.board.platform)
[ -z "$SOC" ] && SOC=$(getprop ro.hardware)
[ -z "$SOC" ] && SOC=$(getprop ro.soc.model | tr '[:upper:]' '[:lower:]')

# RAM information
total_ram_kb=$(grep MemTotal /proc/meminfo | tr -cd '[:digit:]')
total_ram_mb=$((total_ram_kb / 1024))

# Current settings
current_profile=$(getprop sys.perfmtk.current_profile)
current_thermal=$(getprop sys.perfmtk.thermal_state)

# Logging function
log_info() {
  if [[ $LANG == es* ]]; then
    ui_print "- $1"
    ui_print " "
  else
    ui_print "- $2"
    ui_print " "
  fi
}

# Error handling function
abort_install() {
  if [[ $LANG == es* ]]; then
    abort "× $1"
  else
    abort "× $2"
  fi
}

print_sel() {
  if [[ $LANG == es* ]]; then
    ui_print "✓ $1"
    ui_print " "
  else
    ui_print "✓ $2"
    ui_print " "
  fi
}

# Function to verify system requirements
verify_requirements() {
  # Verify installation environment
  if ! $BOOTMODE; then
    abort_install \
      "Instalación desde Recovery no soportada." \
      "Installation from Recovery is not supported."
  fi

  # Verify SOC compatibility across diverse OEMs (Xiaomi, Samsung, Vivo, Oplus, Transsion, Moto)
  local is_mtk=false
  if [[ $SOC == mt* ]]; then
    is_mtk=true
  elif [[ $(getprop ro.hardware) == mt* ]]; then
    SOC=$(getprop ro.hardware)
    is_mtk=true
  elif [[ $(getprop ro.soc.model | tr '[:upper:]' '[:lower:]') == mt* ]]; then
    SOC=$(getprop ro.soc.model | tr '[:upper:]' '[:lower:]')
    is_mtk=true
  elif grep -qi "mediatek" /proc/cpuinfo 2>/dev/null || [[ $(getprop ro.soc.manufacturer) == *[Mm]ediatek* ]]; then
    is_mtk=true
  fi

  if ! $is_mtk; then
    abort_install \
      "[$SOC] no es compatible (Se requiere un SoC MediaTek)." \
      "[$SOC] is not supported (A MediaTek SoC is required)."
  fi

  # Verify architecture
  if [[ $ARCH != arm* ]]; then
    abort_install \
      "Arquitectura [$ARCH] no soportada." \
      "Architecture [$ARCH] not supported."
  fi

  log_info \
    "Dispositivo: $(toupper "$BRAND") | SOC: $SOC" \
    "Device: $(toupper "$BRAND") | SOC: $SOC"

  log_info \
    "RAM Total: ${total_ram_mb} MB" \
    "Total RAM: ${total_ram_mb} MB"
}

# Function to replace (or uncomment/append) a property in system.prop
replace_property() {
  local property="$1"
  local value="$2"
  local file="$3"

  if [ ! -f "$file" ]; then
    abort_install \
      "Archivo $file no encontrado." \
      "File $file not found."
  fi

  if grep -qE "^[#[:space:]]*$property=" "$file" 2>/dev/null; then
    if ! sed -i "s|^[#[:space:]]*$property=.*|$property=$value|g" "$file"; then
      abort_install \
        "Error al modificar $property en $file." \
        "Error modifying $property in $file."
    fi
  else
    printf "\n%s=%s\n" "$property" "$value" >> "$file" || abort_install \
      "Error al agregar $property en $file." \
      "Error appending $property to $file."
  fi
}

# Configure system properties based on device specs
configure_system_props() {
  local prop_file="$1"

  if [ "$total_ram_mb" -le 2200 ]; then
    # ----------------------------------------------------------------
    #  2 GB RAM or lower (Low-RAM Target)
    # ----------------------------------------------------------------
    replace_property "ro.config.low_ram" "true" "$prop_file"
    replace_property "dalvik.vm.usap_pool_enabled" "false" "$prop_file"
    replace_property "dalvik.vm.heapstartsize" "8m" "$prop_file"
    replace_property "dalvik.vm.heapmaxfree" "8m" "$prop_file"
    replace_property "dalvik.vm.dex2oat-Xmx" "256m" "$prop_file"

  elif [ "$total_ram_mb" -le 3500 ]; then
    # ----------------------------------------------------------------
    #  3 GB RAM (Mid-Low Target)
    # ----------------------------------------------------------------
    replace_property "ro.config.low_ram" "false" "$prop_file"
    replace_property "dalvik.vm.usap_pool_enabled" "true" "$prop_file"
    replace_property "dalvik.vm.usap_pool_size_max" "3" "$prop_file"
    replace_property "dalvik.vm.heapstartsize" "8m" "$prop_file"
    replace_property "dalvik.vm.heapmaxfree" "8m" "$prop_file"
    replace_property "dalvik.vm.dex2oat-Xmx" "512m" "$prop_file"

  elif [ "$total_ram_mb" -le 5200 ]; then
    # ----------------------------------------------------------------
    #  4 GB RAM (Standard Mid Target)
    # ----------------------------------------------------------------    
    replace_property "ro.config.low_ram" "false" "$prop_file"
    replace_property "dalvik.vm.usap_pool_enabled" "true" "$prop_file"
    replace_property "dalvik.vm.usap_pool_size_max" "4" "$prop_file"
    replace_property "dalvik.vm.heapstartsize" "8m" "$prop_file"
    replace_property "dalvik.vm.heapmaxfree" "16m" "$prop_file"
    replace_property "dalvik.vm.dex2oat-Xmx" "1024m" "$prop_file"

  else
    # ----------------------------------------------------------------
    #  6 GB - 8 GB RAM or higher (High-End Target)
    # ----------------------------------------------------------------
    replace_property "ro.config.low_ram" "false" "$prop_file"
    replace_property "dalvik.vm.usap_pool_enabled" "true" "$prop_file"
    replace_property "dalvik.vm.usap_pool_size_max" "5" "$prop_file"
    replace_property "dalvik.vm.heapstartsize" "16m" "$prop_file"
    replace_property "dalvik.vm.heapmaxfree" "32m" "$prop_file"
    replace_property "dalvik.vm.dex2oat-Xmx" "1024m" "$prop_file"
  fi

  # Set graphics driver (computed after verify_requirements resolves SOC fallbacks)
  local gfx_driver="com.mediatek.$SOC.gamedriver"
  replace_property "ro.gfx.driver.0" "$gfx_driver" "$prop_file"

  # Set module configuration
  set_mod_config "$prop_file"
}

# Function to set the module configuration
set_mod_config() {
  replace_property "sys.perfmtk.current_profile" "${current_profile:-balanced}" "$1"
  replace_property "sys.perfmtk.thermal_state"   "${current_thermal:-enabled}" "$1"
}

# Helper for volume key polling loops
wait_volume_key() {
  local delay="${1:-10}"
  local ev_file="$TMPDIR/events"
  : > "$ev_file"

  local vol_devs
  vol_devs=$(/system/bin/getevent -lp 2>/dev/null | awk '
    /^add device/ { dev=$NF }
    /KEY_VOLUME(UP|DOWN)/ { if (dev != "" && !seen[dev]++) print dev }
  ')

  if [ -z "$vol_devs" ]; then
    local end_ts=$(( $(date +%s) + delay ))
    while [ "$(date +%s)" -lt "$end_ts" ]; do
      timeout 1 /system/bin/getevent -lqc 1 >"$ev_file" 2>&1
      if grep -q 'KEY_VOLUMEUP.*DOWN' "$ev_file"; then
        return 1
      elif grep -q 'KEY_VOLUMEDOWN.*DOWN' "$ev_file"; then
        return 2
      fi
    done
    return 0
  fi

  local pids=""
  local dev
  for dev in $vol_devs; do
    (
      while :; do
        /system/bin/getevent -lqc 1 "$dev" >>"$ev_file" 2>/dev/null || break
      done
    ) &
    pids="$pids $!"
  done

  local rc=0
  local end_ts=$(( $(date +%s) + delay ))
  while [ "$(date +%s)" -lt "$end_ts" ]; do
    if grep -q 'KEY_VOLUMEUP.*DOWN' "$ev_file" 2>/dev/null; then
      rc=1
      break
    elif grep -q 'KEY_VOLUMEDOWN.*DOWN' "$ev_file" 2>/dev/null; then
      rc=2
      break
    fi
    sleep 0.1
  done

  local p
  for p in $pids; do
    pkill -P "$p" 2>/dev/null
    kill "$p" 2>/dev/null
  done
  wait $pids 2>/dev/null
  return "$rc"
}

# Installation Mode Selector
choose_install_mode() {
  local delay=10
  ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [[ $LANG == es* ]]; then
    ui_print "       Modo de Instalación        "
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print " [⚡] Modo Express (Recomendado):"
    ui_print "     Instalación óptima automática."
    ui_print "     (Por defecto al agotarse el tiempo)"
    ui_print " "
    ui_print " [🛠️] Modo Personalizado:"
    ui_print "     Presiona [VOL+] para elegir componentes."
    ui_print "     O presiona [VOL-] para iniciar Express ya."
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "  ⏳ Esperando selección (${delay}s)..."
  else
    ui_print "        Installation Mode         "
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print " [⚡] Express Mode (Recommended):"
    ui_print "     Full optimal automatic install."
    ui_print "     (Default when timer expires)"
    ui_print " "
    ui_print " [🛠️] Custom Mode:"
    ui_print "     Press [VOL+] to select components."
    ui_print "     Or press [VOL-] to start Express now."
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "  ⏳ Waiting for selection (${delay}s)..."
  fi

  local custom_mode=false
  local manual_express=false
  
  wait_volume_key "$delay"
  case "$?" in
    1) custom_mode=true ;;
    2) manual_express=true ;;
  esac

  # Pause to avoid key bounce and let user release key
  sleep 0.4

  if $custom_mode; then
    print_sel "Modo Personalizado activado [VOL+]" "Custom Mode activated [VOL+]"
    return 1
  elif $manual_express; then
    print_sel "Modo Express activado [VOL-]" "Express Mode activated [VOL-]"
    return 0
  else
    print_sel "Modo Express activado por defecto (Óptimo)" "Express Mode activated by default (Optimal)"
    return 0
  fi
}

# Volume Key Selector (used in Custom Mode)
select_option() {
  local key="$1"
  local delay="${2:-10}"

  local title="" opt1="" desc1="" opt2="" desc2=""

  if [[ $LANG == es* ]]; then
    case "$key" in
      system.prop)
        title="Configuración de system.prop"
        opt1="Ajustes completos"
        desc1="Incluye optimizaciones de render y memoria"
        opt2="Ajustes esenciales"
        desc2="Solo configuración base para estabilidad"
        ;;
      post-fs-data.sh)
        title="Instalación de post-fs-data.sh"
        opt1="Instalar script"
        desc1="Aplica optimizaciones tempranas de VM, red y PowerHook"
        opt2="No instalar script"
        desc2="Omitir post-fs-data"
        ;;
      service.sh)
        title="Configuración de service.sh"
        opt1="Ajustes completos"
        desc1="Tweaks de PPM legacy y arranque del daemon"
        opt2="Ajustes esenciales"
        desc2="Solo arranque esencial del daemon"
        ;;
    esac
  else
    case "$key" in
      system.prop)
        title="system.prop Configuration"
        opt1="Complete settings"
        desc1="Includes rendering and memory optimizations"
        opt2="Essential settings only"
        desc2="Basic configuration for stability"
        ;;
      post-fs-data.sh)
        title="post-fs-data.sh Installation"
        opt1="Install script"
        desc1="Applies early VM, network and PowerHook optimizations"
        opt2="Don't install script"
        desc2="Skip post-fs-data"
        ;;
      service.sh)
        title="service.sh Configuration"
        opt1="Complete settings"
        desc1="Legacy PPM tweaks and daemon startup"
        opt2="Essential settings only"
        desc2="Only essential daemon launch"
        ;;
    esac
  fi

  ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ui_print "   $title"
  ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ui_print ""
  ui_print "[1] ⬆️  VOL+ : $opt1"
  ui_print "    $desc1"
  ui_print ""
  ui_print "[2] ⬇️  VOL- : $opt2"
  ui_print "    $desc2"
  ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [[ $LANG == es* ]]; then
    ui_print "  ⏳ Esperando selección (${delay}s)..."
  else
    ui_print "  ⏳ Waiting for selection (${delay}s)..."
  fi

  local chosen=0
  wait_volume_key "$delay"
  chosen="$?"

  # Pause to avoid key bounce and let user release key
  sleep 0.4

  if [ "$chosen" -eq 1 ]; then
    print_sel "Opción 1 seleccionada [VOL+]" "Option 1 selected [VOL+]"
    return 0
  elif [ "$chosen" -eq 2 ]; then
    print_sel "Opción 2 seleccionada [VOL-]" "Option 2 selected [VOL-]"
    return 1
  else
    print_sel "Sin tecla detectada. Usando opción por defecto [1]..." "No key detected. Using default option [1]..."
    return 0
  fi
}

# Restore configuration
restore_config() {
  local config_dir="$MODPATH/config"
  local live_config="/data/adb/modules/perfmtk/config"

  if [ -d "$live_config" ]; then
    log_info \
      "Restaurando configuración anterior..." \
      "Restoring previous configuration..."

    mkdir -p "$config_dir"

    if cp -af "$live_config/." "$config_dir/" 2>/dev/null; then
      log_info \
        "Configuración restaurada exitosamente" \
        "Configuration restored successfully"
    fi
  fi

  # Migrate unmodified 8GB performance VM presets to low-thrash gaming defaults (5/20/2000/50):
  #   - older legacy preset:  50/60/1000/80
  #   - transitional preset:  30/40/500/60
  if [ "${total_ram_mb:-0}" -gt 0 ] && [ "$total_ram_mb" -le 8192 ]; then
    for perf_conf in "$config_dir/profiles/performance.conf" "$config_dir/performance.conf"; do
      [ -f "$perf_conf" ] || continue
      if grep -q '^SWAPPINESS=50$' "$perf_conf" 2>/dev/null && \
         grep -q '^WATERMARK_SCALE_FACTOR=60$' "$perf_conf" 2>/dev/null && \
         grep -q '^MGLRU_MIN_TTL_MS=1000$' "$perf_conf" 2>/dev/null && \
         grep -q '^VFS_CACHE_PRESSURE=80$' "$perf_conf" 2>/dev/null; then
        sed -i \
          -e 's/^SWAPPINESS=50$/SWAPPINESS=5/' \
          -e 's/^WATERMARK_SCALE_FACTOR=60$/WATERMARK_SCALE_FACTOR=20/' \
          -e 's/^MGLRU_MIN_TTL_MS=1000$/MGLRU_MIN_TTL_MS=2000/' \
          -e 's/^VFS_CACHE_PRESSURE=80$/VFS_CACHE_PRESSURE=50/' \
          "$perf_conf" 2>/dev/null || true
        log_info \
          "Migrando ajustes VM de performance (preset legado) a valores gaming 8GB (5/20/2000/50)..." \
          "Migrating legacy performance VM preset to 8GB gaming defaults (5/20/2000/50)..."
      elif grep -q '^SWAPPINESS=30$' "$perf_conf" 2>/dev/null && \
           grep -q '^WATERMARK_SCALE_FACTOR=40$' "$perf_conf" 2>/dev/null && \
           grep -q '^MGLRU_MIN_TTL_MS=500$' "$perf_conf" 2>/dev/null && \
           grep -q '^VFS_CACHE_PRESSURE=60$' "$perf_conf" 2>/dev/null; then
        sed -i \
          -e 's/^SWAPPINESS=30$/SWAPPINESS=5/' \
          -e 's/^WATERMARK_SCALE_FACTOR=40$/WATERMARK_SCALE_FACTOR=20/' \
          -e 's/^MGLRU_MIN_TTL_MS=500$/MGLRU_MIN_TTL_MS=2000/' \
          -e 's/^VFS_CACHE_PRESSURE=60$/VFS_CACHE_PRESSURE=50/' \
          "$perf_conf" 2>/dev/null || true
        log_info \
          "Migrando ajustes VM de performance a valores gaming 8GB (5/20/2000/50)..." \
          "Migrating performance VM preset to 8GB gaming defaults (5/20/2000/50)..."
      fi
    done
  fi
}

# Install module files
install_module() {
  log_info \
    "Extrayendo archivos del módulo..." \
    "Extracting module files..."

  if ! unzip -o "$ZIPFILE" -x 'META-INF/*' 'LICENSE' -d "$MODPATH" >&2; then
    abort_install \
      "Error al extraer los archivos del ZIP." \
      "Error extracting files from ZIP."
  fi

  # Determine installation mode: Express (default) vs Custom
  local is_express=true
  if ! choose_install_mode; then
    is_express=false
  fi

  # --- system.prop ---
  if $is_express || select_option system.prop 10; then
    log_info \
      "Aplicando configuración completa de system.prop..." \
      "Applying complete system.prop configuration..."
    configure_system_props "$MODPATH/system.prop"
  else
    log_info \
      "Aplicando configuración esencial de system.prop..." \
      "Applying essential system.prop configuration..."
    sed -i '1,/# PerfMTK Config/d' "$MODPATH/system.prop"
    set_mod_config "$MODPATH/system.prop"
  fi

  # --- post-fs-data.sh ---
  if $is_express || select_option post-fs-data.sh 10; then
    log_info \
      "Instalando post-fs-data.sh..." \
      "Installing post-fs-data.sh..."
  else
    log_info \
      "Omitiendo tweaks tempranos (solo manteniendo PowerHook overlay)..." \
      "Skipping early kernel tweaks (keeping PowerHook overlay only)..."
    cat << 'EOF' > "$MODPATH/post-fs-data.sh"
#!/system/bin/sh
MODDIR=${0%/*}

if [ -f "$MODDIR/powerhook-setup.sh" ]; then
  sh "$MODDIR/powerhook-setup.sh" mount 2>/dev/null || true
fi
EOF
  fi

  # --- service.sh ---
  if $is_express || select_option service.sh 10; then
    log_info \
      "Aplicando configuración completa de service.sh..." \
      "Applying complete service.sh configuration..."
  else
    log_info \
      "Aplicando configuración esencial de service.sh..." \
      "Applying essential service.sh configuration..."
    sed -i '/# BEGIN_OPTIMIZATIONS_PPM/,/# END_OPTIMIZATIONS_PPM/d' "$MODPATH/service.sh"
  fi

  # --- Daemon & CLI Binaries ---
  log_info \
    "Instalando binarios nativos ($ABI)..." \
    "Installing native binaries ($ABI)..."

  # CLI & Daemon placed in system/bin (with module-root symlink for backwards compatibility)
  mkdir -p "$MODPATH/system/bin"
  if [ -f "$MODPATH/common/$ABI/perfmtkd" ]; then
    mv "$MODPATH/common/$ABI/perfmtkd" "$MODPATH/system/bin/perfmtkd"
    ln -sf "system/bin/perfmtkd" "$MODPATH/perfmtkd" 2>/dev/null || \
      cp -f "$MODPATH/system/bin/perfmtkd" "$MODPATH/perfmtkd"
  fi

  if [ -f "$MODPATH/common/$ABI/perfmtk" ]; then
    mv "$MODPATH/common/$ABI/perfmtk" "$MODPATH/system/bin/perfmtk"
  fi

  # Compatibility wrapper for thermal_limit forwarding directly to perfmtk
  cat << 'EOF' > "$MODPATH/system/bin/thermal_limit"
#!/system/bin/sh

exec "${0%/*}/perfmtk" thermal "$@"
EOF

  # Ensure config folder structure
  mkdir -p "$MODPATH/config"
  if [ -f "$MODPATH/app_profiles.conf" ]; then
    mv "$MODPATH/app_profiles.conf" "$MODPATH/config/app_profiles.conf"
  fi

  # Cleanup common architectures directory
  if [ -f "$MODPATH/common/$ABI/perfmtk_powerwrap" ] && [ -f "$MODPATH/common/$ABI/libperfmtk_powerhook.so" ]; then
    mv "$MODPATH/common/$ABI/perfmtk_powerwrap" "$MODPATH/perfmtk_powerwrap"
    mv "$MODPATH/common/$ABI/libperfmtk_powerhook.so" "$MODPATH/libperfmtk_powerhook.so"
  fi

  rm -rf "$MODPATH/common"

  # Permissions
  set_perm_recursive "$MODPATH"            0 0    0755 0644
  set_perm_recursive "$MODPATH/system/bin" 0 2000 0755 0755
  
  [ -f "$MODPATH/powerhook-setup.sh" ] && set_perm "$MODPATH/powerhook-setup.sh" 0 2000 0755
  [ -f "$MODPATH/perfmtk_powerwrap" ] && set_perm "$MODPATH/perfmtk_powerwrap" 0 2000 0755
  if [ -f "$MODPATH/perfmtkd" ] && [ ! -L "$MODPATH/perfmtkd" ]; then
    set_perm "$MODPATH/perfmtkd" 0 2000 0755
  fi

  # Symlink perfmtk and thermal_limit in root PATH pointing to active module path
  for bin_dir in /data/adb/ksu/bin /data/adb/ap/bin; do
    if [ -d "$bin_dir" ]; then
      ln -sf "/data/adb/modules/perfmtk/system/bin/perfmtk" "$bin_dir/perfmtk" 2>/dev/null || true
      ln -sf "/data/adb/modules/perfmtk/system/bin/thermal_limit" "$bin_dir/thermal_limit" 2>/dev/null || true
    fi
  done
}

# Print module banner
print_banner() {
  ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ui_print "            $MODNAME $MODVER      "
  ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ui_print "                            "
  ui_print " ███╗░░░███╗████████╗██╗░░██╗"
  ui_print " ████╗░████║╚══██╔══╝██║░██╔╝"
  ui_print " ██╔████╔██║░░░██║░░░█████═╝░"
  ui_print " ██║╚██╔╝██║░░░██║░░░██╔═██╗░"
  ui_print " ██║░╚═╝░██║░░░██║░░░██║░╚██╗"
  ui_print " ╚═╝░░░░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝"
  ui_print " "
}

# Main
print_banner
verify_requirements
sleep 0.5

log_info \
  "Por $MODAUTH" \
  "By $MODAUTH"

log_info \
  "Desbloquea todo el potencial de tu $(toupper $BRAND)" \
  "Unlock the full potential of your $(toupper $BRAND)"

sleep 1

install_module
restore_config

ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $LANG == es* ]]; then
  ui_print "    ✓ ¡Instalación Completada!    "
  ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ui_print " • Daemon : perfmtkd (activo al reiniciar)"
  ui_print " • CLI    : escribe 'su -c perfmtk' en Termux"
  ui_print " • Reinicia el teléfono para aplicar."
else
  ui_print "   ✓ Installation Completed!      "
  ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ui_print " • Daemon : perfmtkd (ready on boot)"
  ui_print " • CLI    : run 'su -c perfmtk' in Termux"
  ui_print " • Reboot your device to apply."
fi
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
