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

# GFX driver
gfx_driver="com.mediatek.$SOC.gamedriver"

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

# Function to replace a property in system.prop
replace_property() {
  local property="$1"
  local value="$2"
  local file="$3"

  if [ ! -f "$file" ]; then
    abort_install \
      "Archivo $file no encontrado." \
      "File $file not found."
  fi

  if ! sed -i "s/$property=.*/$property=$value/g" "$file"; then
    abort_install \
      "Error al modificar $property en $file." \
      "Error modifying $property in $file."
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

  # Set graphics driver
  replace_property "ro.gfx.driver.0" "$gfx_driver" "$prop_file"

  # Set module configuration
  set_mod_config "$prop_file"
}

# Function to set the module configuration
set_mod_config() {
  replace_property "sys.perfmtk.current_profile" "${current_profile:-balanced}" "$1"
  replace_property "sys.perfmtk.thermal_state"   "${current_thermal:-enabled}" "$1"
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
  local remaining=$delay

  while [ "$remaining" -gt 0 ]; do
    timeout 1 /system/bin/getevent -lqc 1 >$TMPDIR/events 2>&1
    if grep -q 'KEY_VOLUMEUP.*DOWN' $TMPDIR/events; then
      custom_mode=true
      break
    elif grep -q 'KEY_VOLUMEDOWN.*DOWN' $TMPDIR/events; then
      manual_express=true
      break
    fi

    remaining=$((remaining - 1))
  done

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
        desc1="Aplica optimizaciones tempranas de kernel y cpusets"
        opt2="No instalar script"
        desc2="Omitir post-fs-data"
        ;;
      service.sh)
        title="Configuración de service.sh"
        opt1="Ajustes completos"
        desc1="Optimizaciones de I/O y arranque de servicios"
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
        desc1="Applies early kernel and cpuset optimizations"
        opt2="Don't install script"
        desc2="Skip post-fs-data"
        ;;
      service.sh)
        title="service.sh Configuration"
        opt1="Complete settings"
        desc1="I/O tweaks and service startup"
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

  local remaining=$delay
  local chosen=0

  while [ "$remaining" -gt 0 ]; do
    timeout 1 /system/bin/getevent -lqc 1 >$TMPDIR/events 2>&1
    if grep -q 'KEY_VOLUMEUP.*DOWN' $TMPDIR/events; then
      chosen=1
      break
    elif grep -q 'KEY_VOLUMEDOWN.*DOWN' $TMPDIR/events; then
      chosen=2
      break
    fi

    remaining=$((remaining - 1))
  done

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

# Backup existing configuration
backup_config() {
  local backup_dir="/data/adb/perfmtk_backup"

  if [ -d "/data/adb/modules/perfmtk/config" ]; then
    log_info \
      "Respaldando configuración existente..." \
      "Backing up existing configuration..."

    mkdir -p "$backup_dir"
    cp -r /data/adb/modules/perfmtk/config/* "$backup_dir/" 2>/dev/null || true
  fi

  # Preserve legacy app_profiles.conf if exists
  if [ -f "/data/local/app_profiles.conf" ] && [ ! -f "$backup_dir/app_profiles.conf" ]; then
    mkdir -p "$backup_dir"
    cp "/data/local/app_profiles.conf" "$backup_dir/app_profiles.conf" 2>/dev/null || true
  fi
}

# Restore configuration
restore_config() {
  local config_dir="$MODPATH/config"
  local backup_dir="/data/adb/perfmtk_backup"

  if [ -d "$backup_dir" ]; then
    log_info \
      "Restaurando configuración anterior..." \
      "Restoring previous configuration..."

    mkdir -p "$config_dir"
    cp -r "$backup_dir"/* "$config_dir/" 2>/dev/null || true
    rm -rf "$backup_dir"

    log_info \
      "Configuración restaurada exitosamente" \
      "Configuration restored successfully"
  fi

  # Maintain compatibility link for app_profiles
  if [ -f "$config_dir/app_profiles.conf" ]; then
    ln -sf "$config_dir/app_profiles.conf" /data/local/app_profiles.conf 2>/dev/null || true
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
    sed -i '1,/# PerfXT config/d' "$MODPATH/system.prop"
    set_mod_config "$MODPATH/system.prop"
  fi

  # --- post-fs-data.sh ---
  if $is_express || select_option post-fs-data.sh 10; then
    log_info \
      "Instalando post-fs-data.sh..." \
      "Installing post-fs-data.sh..."
  else
    log_info \
      "Omitiendo post-fs-data.sh..." \
      "Skipping post-fs-data.sh..."
    rm -f "$MODPATH/post-fs-data.sh"
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
    sed -i '/# BEGIN_OPTIMIZATIONS_IO/,/# END_OPTIMIZATIONS_IO/d'   "$MODPATH/service.sh"
  fi

  # --- Daemon & CLI Binaries ---
  log_info \
    "Instalando binarios nativos ($ABI)..." \
    "Installing native binaries ($ABI)..."

  # Daemon: perfmtkd placed in module root
  if [ -f "$MODPATH/common/$ABI/perfmtkd" ]; then
    mv "$MODPATH/common/$ABI/perfmtkd" "$MODPATH/perfmtkd"
  fi

  # CLI: perfmtk placed in system/bin
  mkdir -p "$MODPATH/system/bin"
  if [ -f "$MODPATH/common/$ABI/perfmtk" ]; then
    mv "$MODPATH/common/$ABI/perfmtk" "$MODPATH/system/bin/perfmtk"
  fi

  # Compatibility wrapper for thermal_limit forwarding directly to perfmtk
  cat << 'EOF' > "$MODPATH/system/bin/thermal_limit"
#!/system/bin/sh

exec perfmtk thermal "$@"
EOF

  # Ensure config folder structure
  mkdir -p "$MODPATH/config"
  if [ -f "$MODPATH/app_profiles.conf" ]; then
    mv "$MODPATH/app_profiles.conf" "$MODPATH/config/app_profiles.conf"
  fi

  # Cleanup common architectures directory
  rm -rf "$MODPATH/common"

  # Permissions
  set_perm_recursive "$MODPATH"            0 0    0755 0644
  set_perm_recursive "$MODPATH/system/bin" 0 2000 0755 0755
  if [ -f "$MODPATH/perfmtkd" ]; then
    set_perm "$MODPATH/perfmtkd" 0 0 0755
  fi

  # Ensure perfmtk and thermal_limit are immediately available in root PATH
  for bin_dir in /data/adb/ksu/bin /data/adb/ap/bin /data/adb/magisk; do
    if [ -d "$bin_dir" ]; then
      cp -f "$MODPATH/system/bin/perfmtk" "$bin_dir/perfmtk" 2>/dev/null || ln -sf "/data/adb/modules/perfmtk/system/bin/perfmtk" "$bin_dir/perfmtk" 2>/dev/null
      cp -f "$MODPATH/system/bin/thermal_limit" "$bin_dir/thermal_limit" 2>/dev/null || ln -sf "/data/adb/modules/perfmtk/system/bin/thermal_limit" "$bin_dir/thermal_limit" 2>/dev/null
      chmod 0755 "$bin_dir/perfmtk" "$bin_dir/thermal_limit" 2>/dev/null || true
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

backup_config
install_module
restore_config

# Generate initial configs if fresh install
if [ ! -f "$MODPATH/config/device.conf" ]; then
  log_info \
    "Generando configuraciones iniciales del hardware..." \
    "Generating initial hardware configurations..."
  mkdir -p "$MODPATH/config"
  "$MODPATH/system/bin/perfmtk" -d >/dev/null 2>&1 || true
  "$MODPATH/system/bin/perfmtk" -g >/dev/null 2>&1 || true
  if [ -d "/data/adb/modules/perfmtk/config" ] && [ "$MODPATH" != "/data/adb/modules/perfmtk" ]; then
    cp -r /data/adb/modules/perfmtk/config/* "$MODPATH/config/" 2>/dev/null || true
  fi
fi

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
