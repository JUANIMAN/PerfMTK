SKIPUNZIP=1

# Module version
MODVER=$(grep_prop version $TMPDIR/module.prop)

# System language
SYSLANG=$(getprop persist.sys.locale)

# Device brand
BRAND=$(getprop ro.product.brand)

# SOC
soc=$(getprop ro.hardware)

# Function to check meow.cfg existence and set egl property
set_egl_property() {
  meow_cfg="/system/vendor/etc/meow.cfg"
  if [ -f $meow_cfg ]; then
    sed -i "s/ro.hardware.egl=/ro.hardware.egl=meow/" "$file.bak"
  else
    sed -i "s/ro.hardware.egl=/ro.hardware.egl=mali/" "$file.bak"
  fi
}

# Function to check RAM size and set low_ram property
set_low_ram_property() {
  total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  total_ram_mb=$((total_ram_kb / 1024))
  if [ $total_ram_mb -lt 3072 ]; then
    sed -i "s/ro.config.low_ram=/ro.config.low_ram=true/" "$file.bak"
  else
    sed -i "s/ro.config.low_ram=/ro.config.low_ram=false/" "$file.bak"
  fi
}

# Function to set gfx.driver.0 property
set_gfx_driver_property() {
  gfxgd=$(getprop ro.gfx.driver.0)
  if [ -z $gfxgd ]; then
    gfxgd="com.mediatek.$soc.gamedriver"
  fi
  sed -i "s/ro.gfx.driver.0=/ro.gfx.driver.0=$gfxgd/" "$file.bak"
}

install_module() {
  unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2
  file="$MODPATH/system.prop"
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
