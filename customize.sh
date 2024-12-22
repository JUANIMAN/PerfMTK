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
  replace_property "sys.perfmtk.current_profile" "${current_profile:-balanced}" "$prop_file"
  replace_property "sys.perfmtk.thermal_state" "${current_thermal:-enabled}" "$prop_file"
}

# volume selection
select_option() {
  local title_es=$1
  local title_en=$2
  local opt1_es=$3
  local opt1_en=$4
  local opt2_es=$5
  local opt2_en=$6
  local delay=${7:-5}

  if [[ $LANG == es* ]]; then
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "   $title_es"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print ""
    ui_print "[1] ⬆️ VOL+ : $opt1_es"
    ui_print "[2] ⬇️ VOL- : $opt2_es"
    ui_print ""
    ui_print "⏳ Esperando selección... ($delay s)"
    ui_print ""
  else
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "   $title_en"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print ""
    ui_print "[1] ⬆️ VOL+ : $opt1_en"
    ui_print "[2] ⬇️ VOL- : $opt2_en"
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
    log_info "Usando método alternativo de detección..."
  else
    log_info "Using alternative detection method..."
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
      "No se detectó ninguna tecla de volumen" \
      "No volume key detected"
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
      "Ajustes adicionales del $file" \
      "Additional settings of $file" \
      "Ajustes esenciales del $file" \
      "Essential settings of $file" \
      "$delay"
    result=$?
  elif [[ $file == "post-fs-data.sh" ]]; then
    select_option \
      "Instalación de $file" \
      "$file Installation" \
      "Instalar (Puede causar bootloop)" \
      "Install (May cause bootloop)" \
      "No instalar (Recomendado si hay problemas)" \
      "Don't install (Recommended if issues arise)" \
      "$delay"
    result=$?
  elif [[ $file == "service.sh" ]]; then
    select_option \
      "Configuración de $file" \
      "$file Configuration" \
      "Ajustes adicionales del $file" \
      "Additional settings of $file" \
      "Ajustes esenciales del $file" \
      "Essential settings of $file" \
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
      "Error al extraer los archivos" \
      "Error extracting files"
  fi

  chmod -R 0755 "$MODPATH/common"

  local prop_file="$MODPATH/system.prop"
  cp "$prop_file" "$prop_file.bak"

  install_message system.prop 10

  if [ $? -eq 1 ]; then
    sed -i '1,31d' "$prop_file.bak"
  fi

  sleep 1

  install_message post-fs-data.sh 10

  if [ $? -eq 1 ]; then
    rm "$MODPATH/post-fs-data.sh"
  fi

  sleep 1

  install_message service.sh 10

  if [ $? -eq 1 ]; then
    sed -i '8,52d' "$MODPATH/service.sh"
  fi

  sleep 1

  configure_system_props "$prop_file.bak"

  log_info \
    "Configurando propiedades del sistema..." \
    "Configuring system properties..."

  mv "$prop_file.bak" "$prop_file"

  sleep 1

  # clean
  rm -rf "$MODPATH/common" 2>/dev/null

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
