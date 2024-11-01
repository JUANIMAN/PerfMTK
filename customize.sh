SKIPUNZIP=1

# Module information
MODVER=$(grep_prop version "$TMPDIR/module.prop")
MODAUTH=$(grep_prop author "$TMPDIR/module.prop")

# System information
BRAND=$(getprop ro.product.brand)
SOC=$(getprop ro.hardware)
SYSLANG=$(getprop persist.sys.locale)

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
  if [[ $SYSLANG == es* ]]; then
    ui_print "- $1"
    ui_print " "
  else
    ui_print "- $2"
    ui_print " "
  fi
}

# Error handling function
abort_install() {
  if [[ $SYSLANG == es* ]]; then
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
  [ -z "$current_profile" ] && current_profile="balanced"
  [ -z "$current_thermal" ] && current_thermal="enabled"

  replace_property "sys.perfmtk.current_profile" "$current_profile" "$prop_file"
  replace_property "sys.perfmtk.thermal_state" "$current_thermal" "$prop_file"
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

  sleep 0.4

  local prop_file="$MODPATH/system.prop"
  cp "$prop_file" "$prop_file.bak"

  log_info \
    "Configurando propiedades del sistema..." \
    "Configuring system properties..."

  configure_system_props "$prop_file.bak"
  mv "$prop_file.bak" "$prop_file"

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
