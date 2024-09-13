SKIPUNZIP=1

# Module version
MODVER=$(grep_prop version $TMPDIR/module.prop)

# System information
SYSLANG=$(getprop persist.sys.locale)
BRAND=$(getprop ro.product.brand)
SOC=$(getprop ro.hardware)

# RAM
total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_ram_mb=$((total_ram_kb / 1024))

# Function to replace a property in the system.prop file
replace_property() {
  local property="$1"
  local value="$2"
  local file="$3"

  sed -i "s/$property=.*/$property=$value/" "$file"
}

# Function to check RAM size and set low_ram property
set_low_ram_property() {
  local file="$1"

  if [ $total_ram_mb -lt 3072 ]; then
    replace_property ro.config.low_ram true "$file"
  else
    replace_property ro.config.low_ram false "$file"
  fi
}

# Function to set gfx.driver.0 property
set_gfx_driver_property() {
  local file="$1"
  local gfxgd="com.mediatek.$SOC.gamedriver"

  replace_property ro.gfx.driver.0 "$gfxgd" "$file"
}

install_perfmtk() {
  unzip -o "$ZIPFILE" -x 'META-INF/*' 'LICENSE' -d $MODPATH >&2

  local prop_file="$MODPATH/system.prop"
  cp "$prop_file" "$prop_file.bak"

  set_low_ram_property "$prop_file.bak"
  set_gfx_driver_property "$prop_file.bak"

  mv "$prop_file.bak" "$prop_file"
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm_recursive $MODPATH/system/bin 0 2000 0755 0755
}

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

if ! $BOOTMODE; then
  abort "! Install from Recovery is not supported"
fi

if [[ $SOC != mt* ]]; then
  if [[ $SYSLANG == es* ]]; then
    abort "× [ $SOC ] no soportado"
  else
    abort "× [ $SOC ] not supported"
  fi
fi

print_banner
sleep 1

if [[ $SYSLANG == es* ]]; then
  ui_print "- Por $MODAUTH"
  ui_print " "
  ui_print "- Desbloquea todo el potencial de tu $(toupper $BRAND)"
  ui_print " "
  ui_print "- Extrayendo archivos del módulo"
  ui_print " "
else
  ui_print "- By $MODAUTH"
  ui_print " "
  ui_print "- Unlock the full potential of your $(toupper $BRAND)"
  ui_print " "
  ui_print "- Extracting module files"
  ui_print " "
fi

install_perfmtk
