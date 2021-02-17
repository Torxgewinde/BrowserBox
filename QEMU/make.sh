#!/bin/bash

################################################################################
#
# BrowserBox, a VM with Firefox preinstalled and preconfigured
# 
# (c) 2020,2021 Tom Stöveken
# 
# License: GPLv3 ff
#
# Create a QEMU VM, this script executes QEMU specific commands
#
################################################################################

MACHINENAME="BrowserBox-$1"
RAM_MB=4096 
HDD_MB=4000

################################################################################

BASEFOLDER="$2"
TMPFOLDER="$3"
PASSWD="$4"

TARBALL="$BASEFOLDER\/$TMPFOLDER\/files.tgz"
cd "$BASEFOLDER/QEMU" || exit 1
MYUUID="$(uuid)"
BBUSER_PASSWORD="$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c10)"

sed -e "s/%hddsize%/$HDD_MB/g" \
    -e "s/%lang%/$1/g" \
    -e "s/%password%/$BBUSER_PASSWORD/g" \
    -e "s#%tarball%#$TARBALL#g" \
    -e "s/firefox-esr-l10n-en//g" browserbox.vmdb.template > "browserbox.vmdb"
echo "$PASSWD" | sudo --stdin vmdb2 "browserbox.vmdb" --output "$MACHINENAME.img" --verbose --rootfs-tarball "browserbox.cache" || exit 1
qemu-img convert -c -O qcow2 "$MACHINENAME.img" "$MACHINENAME.qcow2"
rm -f "$MACHINENAME.img"
rm -f "browserbox.vmdb"

#################################################################################
# export appliance
#################################################################################
sed -e "s/%password%/$BBUSER_PASSWORD/g" -e "s/%uuid%/$MYUUID/g" BrowserBox.xml.template > "$BASEFOLDER/Releases/$MACHINENAME.xml"
mv "$MACHINENAME.qcow2" "$BASEFOLDER/Releases/"
