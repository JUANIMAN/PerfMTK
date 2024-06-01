SKIPUNZIP=1

# Module version
MODVER=$(grep_prop version $TMPDIR/module.prop)

# System language
SYSLANG=$(getprop persist.sys.locale)

# Device brand
BRAND=$(getprop ro.product.brand)

# SOC
soc=$(getprop ro.hardware)

# Function to replace a property in the system.prop file
replace_property() {
  local property="$1"
  local value="$2"
  sed -i "s/$property=/$property=$value/" "$file.bak"
}

# Function to check meow.cfg existence and set egl property
set_egl_property() {
  if [ -f /system/vendor/etc/meow.cfg ]; then
    replace_property ro.hardware.egl meow
  else
    replace_property ro.hardware.egl mali
  fi
}

# Function to check RAM size and set low_ram property
set_low_ram_property() {
  local total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local total_ram_mb=$((total_ram_kb / 1024))
  if [ $total_ram_mb -lt 3072 ]; then
    replace_property ro.config.low_ram true
  else
    replace_property ro.config.low_ram false
  fi
}

# Function to set gfx.driver.0 property
set_gfx_driver_property() {
  local gfxgd=$(getprop ro.gfx.driver.0)
  if [ -z $gfxgd ]; then
    gfxgd="com.mediatek.$soc.gamedriver"
  fi
  replace_property ro.gfx.driver.0 "$gfxgd"
}

install_module() {
  unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2

  local file="$MODPATH/system.prop"
  cp "$file" "$file.bak"

  # Call helper functions
  set_egl_property
  set_low_ram_property
  set_gfx_driver_property

  mv "$file.bak" "$file"
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm_recursive $MODPATH/system/bin 0 0 0775 0775
}

print_name() {
  ui_print "********************************"
  ui_print "          $MODNAME $MODVER      "
  ui_print "********************************"
  ui_print "                            "
  ui_print "███╗░░░███╗████████╗██╗░░██╗"
  ui_print "████╗░████║╚══██╔══╝██║░██╔╝"
  ui_print "██╔████╔██║░░░██║░░░█████═╝░"
  ui_print "██║╚██╔╝██║░░░██║░░░██╔═██╗░"
  ui_print "██║░╚═╝░██║░░░██║░░░██║░╚██╗"
  ui_print "╚═╝░░░░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝"
  ui_print " "
}

print_eng() {
  print_name
  ui_print "- By $MODAUTH"
  ui_print " "
  ui_print "- Unlock the full potential of your $(toupper $BRAND)"
  ui_print " "
  ui_print "- Extracting module files"
  ui_print " "
  install_module
}

print_esp() {
  ui_print "- Por $MODAUTH"
  ui_print " "
  ui_print "- Desbloquea todo el potencial de tu $(toupper $BRAND)"
  ui_print " "
  ui_print "- Extrayendo archivos del módulo"
  ui_print " "
  install_module
}

if ! $BOOTMODE; then
  abort "! Install from Recovery is not supported"
fi

if [[ $soc == mt* ]]; then
  print_name
  sleep 1
  if [[ $SYSLANG == es* ]]; then
    print_esp
  else
    print_eng
  fi
else
  if [[ $SYSLANG == es* ]]; then
    abort "× [ $soc ] no soportado"
  else
    abort "× [ $soc ] not supported"
  fi
fi
