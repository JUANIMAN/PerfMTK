SKIPUNZIP=1

# Module version
MODVER=$(grep_prop version $TMPDIR/module.prop)

# System language
SYSLANG=$(getprop persist.sys.locale)

# Device brand
BRAND=$(getprop ro.product.brand)

# SOC
SOC=$(getprop ro.hardware)

# Function to replace a property in the system.prop file
replace_property() {
  local property="$1"
  local value="$2"

  sed -i "s/$property=/$property=$value/" "$file.bak"
}

# Function to check RAM size and set low_ram property
set_low_ram_property() {
  local total_ram_kb
  local total_ram_mb

  total_ram_kb="$(grep MemTotal /proc/meminfo | awk '{print $2}')"
  total_ram_mb="$(( total_ram_kb / 1024 ))"

  if [ $total_ram_mb -lt 3072 ]; then
    replace_property ro.config.low_ram true
  else
    replace_property ro.config.low_ram false
  fi
}

# Function to set gfx.driver.0 property
set_gfx_driver_property() {
  local gfxgd="com.mediatek.$SOC.gamedriver"
  replace_property ro.gfx.driver.0 "$gfxgd"
}

install_module() {
  unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2

  local file="$MODPATH/system.prop"
  cp "$file" "$file.bak"

  # Call helper functions
  set_low_ram_property
  set_gfx_driver_property

  mv "$file.bak" "$file"
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm_recursive $MODPATH/system/bin 0 0 0775 0775
}

print_banner() {
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

install_module
