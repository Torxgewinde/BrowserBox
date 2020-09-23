#!/bin/bash

################################################################################
#
# BrowserBox, a VM with Firefox preinstalled and preconfigured
# 
# (c) 2020 Tom Stöveken
# 
# License: GPLv3 ff
#
# Create the VitualBox VM
#
################################################################################

BBUSER_PASSWORD="changeme"

MACHINENAME="BrowserBox-$1"
RAM_MB=4096 
HDD_MB=10000

# determine VirtualBox Version
VBOXVERSION="$(VBoxManage --version | sed 's/\([.0-9]\{1,\}\).*/\1/')"
GUESTISO="https://download.virtualbox.org/virtualbox/$VBOXVERSION/VBoxGuestAdditions_$VBOXVERSION.iso"

################################################################################

BASEFOLDER="$2"
ISO="$3"
cd "$BASEFOLDER/VirtualBox" || exit 1

#download guest additions ISO
if [ ! -f "${GUESTISO##*/}" ]; then
	wget --no-verbose --show-progress "$GUESTISO" || exit 1
fi

# unpack guest additions ISO
TMPFOLDER=$(mktemp -d GUESTISO_XXXX) || exit 1
xorriso -osirrox on -indev "${GUESTISO##*/}" -extract / "$TMPFOLDER" || exit 1
chmod -R +w "$TMPFOLDER"

################################################################################
# prepare Virtualbox VM
################################################################################
VBoxManage createvm --name "$MACHINENAME" --ostype "Debian_64" --register --basefolder "$(pwd)"

VBoxManage modifyvm "$MACHINENAME" --ioapic on
VBoxManage modifyvm "$MACHINENAME" --memory $(("$RAM_MB")) --vram 128
VBoxManage modifyvm "$MACHINENAME" --nic1 nat
VBoxManage modifyvm "$MACHINENAME" --cpus 4
VBoxManage modifyvm "$MACHINENAME" --graphicscontroller vboxsvga
VBoxManage modifyvm "$MACHINENAME" --audioout on
VBoxManage modifyvm "$MACHINENAME" --clipboard bidirectional

VBoxManage createhd --filename "$BASEFOLDER/VirtualBox/$MACHINENAME.vdi" --size $(("$HDD_MB")) --format VDI
VBoxManage storagectl "$MACHINENAME" --name "SATA Controller" --add sata --controller "IntelAhci" --hostiocache on
VBoxManage storageattach "$MACHINENAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium  "$BASEFOLDER/VirtualBox/$MACHINENAME.vdi"

VBoxManage storageattach "$MACHINENAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "$ISO"     
VBoxManage modifyvm "$MACHINENAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none

################################################################################
# Run Virtualbox VM
################################################################################
VBoxManage startvm "$MACHINENAME" --type gui

rm -rf "$TMPFOLDER"
