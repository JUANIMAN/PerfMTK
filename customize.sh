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
  
  # Show system info
  if [[ $LANG == es* ]]; then
    log_info "Dispositivo: $(toupper $BRAND) con SOC $SOC"
    log_info "RAM Total: $total_ram_mb MB"
  else
    log_info "Device: $(toupper $BRAND) with SOC $SOC"
    log_info "Total RAM: $total_ram_mb MB"
  fi
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

  # Set low RAM property
  if [ $total_ram_mb -lt 3072 ]; then
    replace_property "ro.config.low_ram" "true" "$prop_file"
  else
    replace_property "ro.config.low_ram" "false" "$prop_file"
  fi

  # Set graphics driver
  replace_property "ro.gfx.driver.0" "$gfx_driver" "$prop_file"

  # Set module configuration
  set_mod_config "$prop_file"
}

# Function to set the module configuration
set_mod_config() {
  replace_property "sys.perfmtk.current_profile" "${current_profile:-balanced}" "$1"
  replace_property "sys.perfmtk.thermal_state" "${current_thermal:-enabled}" "$1"
}

# Volume Key Selector
select_option() {
  local title_es=$1
  local title_en=$2
  local opt1_es=$3
  local opt1_en=$4
  local opt1_desc_es=$5
  local opt1_desc_en=$6
  local opt2_es=$7
  local opt2_en=$8
  local opt2_desc_es=$9
  local opt2_desc_en=${10}
  local delay=${11:-5}

  if [[ $LANG == es* ]]; then
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "   $title_es"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print ""
    ui_print "[1] ⬆️ VOL+ : $opt1_es"
    ui_print "    $opt1_desc_es"
    ui_print ""
    ui_print "[2] ⬇️ VOL- : $opt2_es"
    ui_print "    $opt2_desc_es"
    ui_print ""
    ui_print "⏳ Esperando selección... ($delay s)"
    ui_print ""
  else
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "   $title_en"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print ""
    ui_print "[1] ⬆️ VOL+ : $opt1_en"
    ui_print "    $opt1_desc_en"
    ui_print ""
    ui_print "[2] ⬇️ VOL- : $opt2_en"
    ui_print "    $opt2_desc_en"
    ui_print ""
    ui_print "⏳ Waiting for selection... ($delay s)"
    ui_print ""
  fi

  # Try getevent first
  local start=$(date +%s)
  local end=$((start + delay))
  while [ $(date +%s) -lt $end ]; do
    timeout 1 /system/bin/getevent -lqc 1 >$TMPDIR/events 2>&1
    if grep -q 'KEY_VOLUMEUP *DOWN' $TMPDIR/events; then
      print_sel \
        "Opción 1 seleccionada" \
        "Option 1 selected"
      return 0
    elif grep -q 'KEY_VOLUMEDOWN *DOWN' $TMPDIR/events; then
      print_sel \
        "Opción 2 seleccionada" \
        "Option 2 selected"
      return 1
    fi
  done

  # Fallback to keycheck if getevent fails
  if [[ $LANG == es* ]]; then
    log_info "Usando método alternativo de detección de teclas..."
  else
    log_info "Using alternative key detection method..."
  fi

  timeout 0 $MODPATH/common/$ABI/keycheck
  timeout $delay $MODPATH/common/$ABI/keycheck
  local sel=$?

  if [ $sel -eq 42 ]; then
    print_sel \
      "Opción 1 seleccionada" \
      "Option 1 selected"
    return 0
  elif [ $sel -eq 41 ]; then
    print_sel \
      "Opción 2 seleccionada" \
      "Option 2 selected"
    return 1
  else
    abort_install \
      "No se detectó ninguna tecla de volumen." \
      "No volume key detected."
  fi
}

install_message() {
  local file="$1"
  local delay="$2"
  local result

  if [[ $file == "system.prop" ]]; then
    select_option \
      "Configuración de $file" \
      "$file Configuration" \
      "Ajustes completos" \
      "Complete settings" \
      "Incluye optimizaciones de rendimiento" \
      "Includes performance optimizations" \
      "Ajustes esenciales" \
      "Essential settings only" \
      "Solo configuración básica para estabilidad" \
      "Only basic configuration for stability" \
      "$delay"
    result=$?
  elif [[ $file == "post-fs-data.sh" ]]; then
    select_option \
      "Instalación de $file" \
      "$file Installation" \
      "Instalar script" \
      "Install script" \
      "Aplica optimizaciones al inicio del sistema (puede causar bootloop)" \
      "Apply optimizations at system startup (may cause bootloop)" \
      "No instalar script" \
      "Don't install script" \
      "Omitir esta optimización (recomendado si hay problemas de estabilidad)" \
      "Skip this optimization (recommended if stability issues arise)" \
      "$delay"
    result=$?
  elif [[ $file == "service.sh" ]]; then
    select_option \
      "Configuración de $file" \
      "$file Configuration" \
      "Ajustes completos" \
      "Complete settings" \
      "Optimizaciones adicionales después del arranque" \
      "Additional optimizations after boot" \
      "Ajustes esenciales" \
      "Essential settings only" \
      "Solo ajustes básicos para estabilidad" \
      "Only basic adjustments for stability" \
      "$delay"
    result=$?
  elif [[ $file == "daemon" ]]; then
   select_option \
      "PerfMTK Daemon" \
      "PerfMTK Daemon" \
      "Instalar Daemon" \
      "Install Daemon" \
      "Permite configurar perfiles específicos por aplicación" \
      "Allows you to configure specific profiles per application" \
      "No instalar Daemon" \
      "Don't install Daemon" \
      "Omitir esta función" \
      "Skip this feature" \
      "$delay"
    result=$?
  fi

  return $result
}

# Install module files
install_module() {
  log_info \
    "Extrayendo archivos del módulo..." \
    "Extracting module files..."

  if ! unzip -o "$ZIPFILE" -x 'META-INF/*' 'LICENSE' -d "$MODPATH" >&2; then
    abort_install \
      "Error al extraer los archivos." \
      "Error extracting files. Check."
  fi

  chmod -R 0755 "$MODPATH/common"

  if ! install_message system.prop 10; then
    log_info \
      "Aplicando configuración esencial de system.prop..." \
      "Applying essential system.prop configuration..."
    sed -i '1,31d' "$MODPATH/system.prop"
    set_mod_config "$MODPATH/system.prop"
  else
    log_info \
      "Aplicando configuración completa de system.prop..." \
      "Applying complete system.prop configuration..."
    configure_system_props "$MODPATH/system.prop"
  fi

  sleep 1

  if ! install_message post-fs-data.sh 10; then
    log_info \
      "Omitiendo la instalación de post-fs-data.sh..." \
      "Skipping post-fs-data.sh installation..."
    rm "$MODPATH/post-fs-data.sh"
  else
    log_info \
      "Instalando post-fs-data.sh..." \
      "Installing post-fs-data.sh..."
  fi

  sleep 1

  if ! install_message service.sh 10; then
    log_info \
      "Aplicando configuración esencial de service.sh..." \
      "Applying essential service.sh configuration..."
    sed -e '8,52d' -e '56,75d' "$MODPATH/service.sh" > "$MODPATH/service.sh.new" &&
      mv "$MODPATH/service.sh.new" "$MODPATH/service.sh"
  else
    log_info \
      "Aplicando configuración completa de service.sh..." \
      "Applying complete service.sh configuration..."
  fi

  sleep 1

  if install_message daemon 10; then
    log_info \
      "Instalando PerfMTK Daemon..." \
      "Installing PerfMTK Daemon..."
    mv "$MODPATH/common/$ABI/perfmtk_daemon" "$MODPATH/system/bin"

    if [ ! -f "/data/local/app_profiles.conf" ]; then
      mv "$MODPATH/app_profiles.conf" "/data/local"
    fi
  else
    log_info \
      "Omitiendo la instalación de PerfMTK Daemon..." \
      "Skipping PerfMTK Daemon installation..."
  fi

  sleep 1

  log_info \
    "Instalando binarios principales..." \
    "Installing main binaries..."
  mv "$MODPATH/common/$ABI/perfmtk" "$MODPATH/system/bin"
  mv "$MODPATH/common/$ABI/thermal_limit" "$MODPATH/system/bin"

  log_info \
    "Configurando archivos del modulo..." \
    "Configuring module files..."

  # clean
  rm -rf "$MODPATH/common" 2>/dev/null
  rm -f "$MODPATH/app_profiles.conf" 2>/dev/null

  sleep 1

  # Set permissions
  set_perm_recursive "$MODPATH" 0 0 0755 0644
  set_perm_recursive "$MODPATH/system/bin" 0 2000 0755 0755
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
sleep 1

log_info \
  "Por $MODAUTH" \
  "By $MODAUTH"

log_info \
  "Desbloquea todo el potencial de tu $(toupper $BRAND)" \
  "Unlock the full potential of your $(toupper $BRAND)"

sleep 0.2

install_module

log_info \
  "¡Instalación completada! Reinicia para aplicar." \
  "Installation completed! Reboot to apply."

