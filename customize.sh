SKIPUNZIP=1

# Module information
MODVER=$(grep_prop version "$TMPDIR/module.prop")
MODAUTH=$(grep_prop author "$TMPDIR/module.prop")

# System information
LANG=$(settings get system system_locales)
BRAND=$(getprop ro.product.vendor.brand)
SOC=$(getprop ro.board.platform)

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

  # Verify SOC compatibility
  if [[ $SOC != mt* ]]; then
    abort_install \
      "[$SOC] no es compatible." \
      "[$SOC] is not supported."
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

# Function to analyze, clone and modify MediaTek's powerscntbl.xml
optimize_power_table() {
  local src_file="/vendor/etc/powerscntbl.xml"
  [ ! -f "$src_file" ] && src_file="/system/vendor/etc/powerscntbl.xml"
  
  local dest_dir="$MODPATH/system/vendor/etc"
  local dest_file="$dest_dir/powerscntbl.xml"

  if [ -f "$src_file" ]; then
    if grep -q 'powerhint="MTKPOWER_HINT_UX_SCROLLING_COMMON"' "$src_file"; then
      log_info \
        "Removiendo rate limits restrictivos en powerscntbl.xml..." \
        "Removing restrictive rate limits in powerscntbl.xml..."

      mkdir -p "$dest_dir"
      cp "$src_file" "$dest_file"

      sed -i '/powerhint="MTKPOWER_HINT_UX_SCROLLING_COMMON"/,/<\/scenario>/ {
        /^[[:space:]]*<data cmd="PERF_RES_SCHED_UTIL_UP_RATE_LIMIT_US_CLUSTER_/d;
        /^[[:space:]]*<data cmd="PERF_RES_SCHED_UTIL_DOWN_RATE_LIMIT_US_CLUSTER_/d;
      }' "$dest_file"
    fi
  fi
}

# Volume Key Selector
select_option() {
  local key="$1"
  local delay="${2:-5}"

  local title="" opt1="" desc1="" opt2="" desc2="" msg_waiting=""

  if [[ $LANG == es* ]]; then
    msg_waiting="⏳ Esperando selección..."
    case "$key" in
      system.prop)
        title="Configuración de system.prop"
        opt1="Ajustes completos"
        desc1="Incluye optimizaciones de rendimiento"
        opt2="Ajustes esenciales"
        desc2="Solo configuración básica para estabilidad"
        ;;
      post-fs-data.sh)
        title="Instalación de post-fs-data.sh"
        opt1="Instalar script"
        desc1="Aplica optimizaciones al inicio (puede causar bootloop)"
        opt2="No instalar script"
        desc2="Omitir (recomendado si hay problemas de estabilidad)"
        ;;
      service.sh)
        title="Configuración de service.sh"
        opt1="Ajustes completos"
        desc1="Optimizaciones adicionales tras el arranque"
        opt2="Ajustes esenciales"
        desc2="Solo ajustes básicos para estabilidad"
        ;;
      daemon)
        title="PerfMTK Daemon"
        opt1="Instalar Daemon"
        desc1="Configura perfiles específicos por aplicación"
        opt2="No instalar Daemon"
        desc2="Omitir esta función"
        ;;
    esac
  else
    msg_waiting="⏳ Waiting for selection..."
    case "$key" in
      system.prop)
        title="system.prop Configuration"
        opt1="Complete settings"
        desc1="Includes performance optimizations"
        opt2="Essential settings only"
        desc2="Only basic configuration for stability"
        ;;
      post-fs-data.sh)
        title="post-fs-data.sh Installation"
        opt1="Install script"
        desc1="Applies optimizations at startup (may cause bootloop)"
        opt2="Don't install script"
        desc2="Skip (recommended if stability issues arise)"
        ;;
      service.sh)
        title="service.sh Configuration"
        opt1="Complete settings"
        desc1="Additional optimizations after boot"
        opt2="Essential settings only"
        desc2="Only basic adjustments for stability"
        ;;
      daemon)
        title="PerfMTK Daemon"
        opt1="Install Daemon"
        desc1="Allows configuring specific profiles per application"
        opt2="Don't install Daemon"
        desc2="Skip this feature"
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
  ui_print ""
  ui_print "$msg_waiting (${delay}s)"
  ui_print ""

  # Try getevent first
  local deadline=$(( $(date +%s) + delay ))

  while [ "$(date +%s)" -lt "$deadline" ]; do
    timeout 1 /system/bin/getevent -lqc 1 >$TMPDIR/events 2>&1
    if grep -q 'KEY_VOLUMEUP *DOWN' $TMPDIR/events; then
      print_sel "Opción 1 seleccionada" "Option 1 selected"
      return 0
    elif grep -q 'KEY_VOLUMEDOWN *DOWN' $TMPDIR/events; then
      print_sel "Opción 2 seleccionada" "Option 2 selected"
      return 1
    fi
  done

  # Fallback to keycheck if getevent fails
  log_info \
    "Usando método alternativo de detección de teclas..." \
    "Using alternative key detection method..."

  timeout 0 "$MODPATH/common/$ABI/keycheck"
  timeout "$delay" "$MODPATH/common/$ABI/keycheck"
  local sel=$?

  if [ $sel -eq 42 ]; then
    print_sel "Opción 1 seleccionada" "Option 1 selected"
    return 0
  elif [ $sel -eq 41 ]; then
    print_sel "Opción 2 seleccionada" "Option 2 selected"
    return 1
  else
    abort_install \
      "No se detectó ninguna tecla de volumen." \
      "No volume key detected."
  fi
}

# Backup existing configuration
backup_config() {
  local config_dir="$MODPATH/config"
  local backup_dir="/data/adb/perfmtk_backup"

  if [ -d "/data/adb/modules/perfmtk/config" ]; then
    log_info \
      "Respaldando configuración existente..." \
      "Backing up existing configuration..."

    mkdir -p "$backup_dir"
    cp -r /data/adb/modules/perfmtk/config/* "$backup_dir/" 2>/dev/null || true
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

  chmod -R 0755 "$MODPATH/common"

  # --- system.prop ---
  if select_option system.prop 10; then
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

  sleep 0.8

  # --- post-fs-data.sh ---
  if select_option post-fs-data.sh 10; then
    log_info \
      "Instalando post-fs-data.sh..." \
      "Installing post-fs-data.sh..."
  else
    log_info \
      "Omitiendo post-fs-data.sh..." \
      "Skipping post-fs-data.sh..."
    rm -f "$MODPATH/post-fs-data.sh"
  fi

  sleep 0.8

  # --- service.sh ---
  if select_option service.sh 10; then
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

  sleep 0.8

  # --- daemon ---
  if select_option daemon 10; then
    log_info \
      "Instalando PerfMTK Daemon..." \
      "Installing PerfMTK Daemon..."
    mv "$MODPATH/common/$ABI/perfmtk_daemon" "$MODPATH/perfmtk_daemon"
    if [ ! -f "/data/local/app_profiles.conf" ]; then
      mv "$MODPATH/app_profiles.conf" "/data/local/app_profiles.conf"
    else
      rm -f "$MODPATH/app_profiles.conf"
    fi
  else
    log_info \
      "Omitiendo PerfMTK Daemon..." \
      "Skipping PerfMTK Daemon..."
    rm -f "$MODPATH/common/$ABI/perfmtk_daemon"
    rm -f "$MODPATH/app_profiles.conf"
  fi

  sleep 0.8

  # --- Main binaries ---
  log_info \
    "Instalando binarios principales..." \
    "Installing main binaries..."
  mv "$MODPATH/common/$ABI/perfmtk"       "$MODPATH/system/bin/perfmtk"
  mv "$MODPATH/common/$ABI/thermal_limit" "$MODPATH/system/bin/thermal_limit"

  # --- MediaTek Power Table Optimization ---
  optimize_power_table

  log_info \
    "Configurando archivos del modulo..." \
    "Configuring module files..."

  # Cleanup
  rm -rf "$MODPATH/common"

  sleep 0.8

  # --- Permissions ---
  set_perm_recursive "$MODPATH"            0 0    0755 0644
  set_perm_recursive "$MODPATH/system/bin" 0 2000 0755 0755

  if [ -f "$MODPATH/perfmtk_daemon" ]; then
    set_perm "$MODPATH/perfmtk_daemon" 0 0 0755
  fi
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

sleep 0.3

backup_config
install_module
restore_config

log_info \
  "¡Instalación completada! Reinicia para aplicar los cambios." \
  "Installation completed! Reboot to apply changes."
