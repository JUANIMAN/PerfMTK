SKIPUNZIP=1

# Module information
MODVER=$(grep_prop version "$TMPDIR/module.prop")
MODAUTH=$(grep_prop author "$TMPDIR/module.prop")

# System information
LANG=$(settings get system system_locales)
BRAND=$(getprop ro.product.vendor.brand)
SOC=$(getprop ro.board.platform)

# RAM information
total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
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

# Function to verify system requirements
verify_requirements() {
  # Verify installation environment
  if ! $BOOTMODE; then
    abort_install \
      "Instalación desde Recovery no soportada" \
      "Installation from Recovery is not supported"
  fi

  # Verify SOC compatibility
  if [[ $SOC != mt* ]]; then
    abort_install \
      "[$SOC] no es compatible" \
      "[$SOC] is not supported"
  fi

  # Verify architecture
  if [[ $ARCH != arm* ]]; then
    abort_install \
      "Arquitectura [$ARCH] no soportada" \
      "Architecture [$ARCH] not supported"
  fi
}

# extract of Volume Key Selector - Addon by Zackptg5 @Github
chooseport_legacy() {
  # Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
  # Calling it first time detects previous input. Calling it second time will do what we want
  [ "$1" ] && local delay=$1 || local delay=3
  local error=false
  while true; do
    timeout 0 $MODPATH/common/$ABI/keycheck
    timeout $delay $MODPATH/common/$ABI/keycheck
    local sel=$?
    if [ $sel -eq 42 ]; then
      return 0
    elif [ $sel -eq 41 ]; then
      return 1
    elif $error; then
      abort_install \
        "¡No se detectó la tecla de volumen!" \
        "Volume key not detected!"
    else
      error=true
      log_info \
        "No se detectó la tecla de volumen. Inténtalo de nuevo" \
        "Volume key not detected. Try again"
    fi
  done
}

# Volume Key Selector function with getevent, improved by JUANIMAN @Github
chooseport() {
  # Original idea by chainfire and ianmacd @xda-developers
  [ "$1" ] && local delay=$1 || local delay=3
  local error=false
  while true; do
    local count=0
    while [ $count -lt $delay ]; do
      timeout 1 /system/bin/getevent -lqc 1 >$TMPDIR/events 2>&1
      count=$((count + 1))
      if grep -q 'KEY_VOLUMEUP *DOWN' $TMPDIR/events; then
        return 0
      elif grep -q 'KEY_VOLUMEDOWN *DOWN' $TMPDIR/events; then
        return 1
      fi
    done
    if $error; then
      log_info \
        "No se detectó la tecla de volumen. Probando con keycheck" \
        "Volume key not detected. Trying keycheck method"
      chooseport_legacy $delay
      return $?
    else
      error=true
      log_info \
        "No se detectó la tecla de volumen. Inténtalo de nuevo" \
        "Volume key not detected. Try again"
    fi
  done
}

# Function to replace a property in system.prop
replace_property() {
  local property="$1"
  local value="$2"
  local file="$3"

  if [ ! -f "$file" ]; then
    abort_install \
      "Archivo $file no encontrado" \
      "File $file not found"
  fi

  if ! sed -i "s/$property=.*/$property=$value/g" "$file"; then
    abort_install \
      "Error al modificar $property en $file" \
      "Error modifying $property in $file"
  fi
}

set_def_conf() {
  local prop_file="$1"

  [ -z "$current_profile" ] && current_profile="balanced"
  [ -z "$current_thermal" ] && current_thermal="enabled"

  replace_property "sys.perfmtk.current_profile" "$current_profile" "$prop_file"
  replace_property "sys.perfmtk.thermal_state" "$current_thermal" "$prop_file"
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

  # Set default config
  set_def_conf "$prop_file"
}

# Install module files
install_module() {
  log_info \
    "Extrayendo archivos del módulo..." \
    "Extracting module files..."

  if ! unzip -o "$ZIPFILE" -x 'META-INF/*' 'LICENSE' -d "$MODPATH" >&2; then
    abort_install \
      "Error al extraer los archivos" \
      "Error extracting files"
  fi

  chmod -R 0755 "$MODPATH/common"

  if [[ $LANG == es* ]]; then
    ui_print "⬆️ Volumen ARRIBA: Configuración Completa"
    ui_print " • Ajustes adicionales del system.prop"
    ui_print ""
    ui_print "⬇️ Volumen ABAJO: Configuración Básica"
    ui_print " • Ajustes esenciales del system.prop"
    ui_print ""
    ui_print "👉 Presiona VOL+/- para continuar..."
    ui_print ""
  else
    ui_print "⬆️ Volume UP: Full Configuration"
    ui_print " • Additional system.prop settings"
    ui_print ""
    ui_print "⬇️ Volume DOWN: Basic Configuration"
    ui_print " • Essential system.prop settings"
    ui_print ""
    ui_print "👉 Press VOL+/- to continue..."
    ui_print ""
  fi

  local prop_file="$MODPATH/system.prop"
  cp "$prop_file" "$prop_file.bak"

  if chooseport 5; then
    # Full settings
    log_info \
      "Instalando todas las configuraciones del system.prop..." \
      "Installing all system.prop settings..."

    configure_system_props "$prop_file.bak"
  else
    # Minimal settings
    log_info \
      "Instalando configuraciones mínimas del system.prop..." \
      "Installing minimal system.prop settings..."

    sed -i '1,31d' "$prop_file.bak"

    # Set default config
    set_def_conf "$prop_file.bak"
  fi

  sleep 0.4

  log_info \
    "Configurando propiedades del sistema..." \
    "Configuring system properties..."

  mv "$prop_file.bak" "$prop_file"

  # clean
  rm -rf "$MODPATH/common" 2>/dev/null

  sleep 0.2

  # Set permissions
  set_perm_recursive "$MODPATH" 0 0 0755 0644
  set_perm_recursive "$MODPATH/system/bin" 0 2000 0755 0755
}

# Print module banner
print_banner() {
  ui_print "********************************"
  ui_print "          $MODNAME $MODVER      "
  ui_print "********************************"
  ui_print "                            "
  ui_print " ███╗░░░███╗████████╗██╗░░██╗"
  ui_print " ████╗░████║╚══██╔══╝██║░██╔╝"
  ui_print " ██╔████╔██║░░░██║░░░█████═╝░"
  ui_print " ██║╚██╔╝██║░░░██║░░░██╔═██╗░"
  ui_print " ██║░╚═╝░██║░░░██║░░░██║░╚██╗"
  ui_print " ╚═╝░░░░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝"
  ui_print " "
}

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
  "¡Instalación completada!" \
  "Installation completed!"

sleep 0.1
