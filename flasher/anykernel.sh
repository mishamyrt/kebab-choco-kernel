# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Choco Kernel by mishamyrt @ myrt.co
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=Kebab
device.name2=kebab
device.name3=Kebabt
device.name4=Kebabt
device.name5=OnePlus8T
device.name6=kb2003
device.name7=KB2003
device.name8=kb2005
device.name9=KB2005
supported.versions=11
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

ui_print " "; ui_print "Trimming partitions...";
$bin/busybox/fstrim -v /data

## AnyKernel install
dump_boot;

write_boot;
## end install

