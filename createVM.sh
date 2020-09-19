#!/bin/bash

################################################################################
#
# BrowserBox, a Virtualbox-VM with Firefox preinstalled and preconfigured
# 
# (c) 2020 Tom Stöveken
# 
# License: GPLv3 ff
#
# This file downloads ISO images of Debian and Virtualbox-Guest-Additions,
# unpacks the ISOs, remasters a new ISO that installs and configures
# the VM unattended.
# 
# Firefox is protected and configured with:
# - Firefox runs inside a VM, so the HOST system is protected
# - Firejail (limits permissions to essential ones)
# - important extensions like uBlock, PrivacyBadger, ...
# - gHacks user.js aka "arkenfox" (improves privacy, reduces telemetry)
#
# To start the process run:
# $ bash createVM.sh
#
# Once the VM is created you can use the BrowserBox
#
################################################################################

BBUSER_PASSWORD="changeme"

MACHINENAME="BrowserBox"
BASEFOLDER="$(pwd)"
RAM_MB=4096 
HDD_MB=10000
ISO="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.5.0-amd64-netinst.iso"
VBOXVERSION="$(VBoxManage --version | sed 's/\([.0-9]\{1,\}\).*/\1/')"
GUESTISO="https://download.virtualbox.org/virtualbox/$VBOXVERSION/VBoxGuestAdditions_$VBOXVERSION.iso"


################################################################################
cd "$BASEFOLDER"
exec 3> >(zenity --progress --title="Create VM" --percentage=0 --width=800 --no-cancel --auto-close)

function msg {
	echo "# $@" >&3
}

function percent {
	#echo "percent: $1"
	echo "$1" >&3
}

################################################################################
# Create modified debian ISO:
#  - Unpack,
#  - Change image content,
#  - Remaster
################################################################################
PERCENT_START=0
PERCENT_END=10
percent $PERCENT_START
msg "downloading ISO"
if [ ! -f "$BASEFOLDER/${ISO##*/}" ]; then
	wget --no-verbose --show-progress "$ISO" 2>&1 | while read line; do
		DWN=$(echo "$line" | sed -E 's/[^0-9]*([0-9]{1,})%[^0-9]*/---\1---/' | sed 's/.*---\(.*\)---.*/\1/g')
		percent "$(( PERCENT_START + (DWN*(PERCENT_END-PERCENT_START)/100) ))"
		msg "downloaded $DWN % of ${ISO##*/}"
	done
fi
percent PERCENT_END

PERCENT_START=10
PERCENT_END=20
percent $PERCENT_START
msg "downloading Guest Additions"
if [ ! -f "$BASEFOLDER/${GUESTISO##*/}" ]; then
	wget --no-verbose --show-progress "$GUESTISO" 2>&1 | while read line; do
		DWN=$(echo "$line" | sed -E 's/[^0-9]*([0-9]{1,})%[^0-9]*/---\1---/' | sed 's/.*---\(.*\)---.*/\1/g')
		percent "$(( PERCENT_START + (DWN*(PERCENT_END-PERCENT_START)/100) ))"
		msg "downloaded $DWN % of ${GUESTISO##*/}"
	done
fi
percent PERCENT_END

#unpack the ISO
percent 30
cd $BASEFOLDER || exit 1
TMPFOLDER=$(mktemp -d ISO_XXXX) || exit 1
TMPFOLDER2=$(mktemp -d GUESTISO_XXXX) || exit 1

msg "extracting ISO image to $TMPFOLDER"
#7z x -bb0 -bd -o"$TMPFOLDER" "$BASEFOLDER/${ISO##*/}"
xorriso -osirrox on -indev "$BASEFOLDER/${ISO##*/}" -extract / "$TMPFOLDER"
xorriso -osirrox on -indev "$BASEFOLDER/${GUESTISO##*/}" -extract / "$TMPFOLDER2"

# change the CD contents
percent 40
msg "modifying CD content"
chmod -R +w "$TMPFOLDER"
chmod -R +w "$TMPFOLDER2"

#modify syslinux to make it automatically run the text based installer
sed -i 's/timeout 0/timeout 20/g' "$TMPFOLDER/isolinux/isolinux.cfg"
sed -i 's/default installgui/default install/g' "$TMPFOLDER/isolinux/gtk.cfg"
sed -i 's/menu default//g' "$TMPFOLDER/isolinux/gtk.cfg"
sed -i 's/label install/label install\n\tmenu default/g' "$TMPFOLDER/isolinux/txt.cfg"
sed -i 's/append \(.*\)/append preseed\/file=\/cdrom\/preseed.cfg locale=de_DE.UTF-8 keymap=de language=de country=DE \1/g' "$TMPFOLDER/isolinux/txt.cfg"

#copy important files into the ISO
cp preseed.cfg "$TMPFOLDER/"
cp postinst.sh "$TMPFOLDER/"
mkdir -p files/root && cp "$TMPFOLDER2/VBoxLinuxAdditions.run" files/root/

#download arkenfox user.js updater script
wget -O files/home/bbuser/.mozilla/firefox/bbuser.default/updater.sh https://raw.githubusercontent.com/arkenfox/user.js/master/updater.sh

# download Add-Ons aka Extensions
msg "downloading extensions"
# The method used below works for FF-Debian-Buster-Version which happens to be "68.xx" (must be <= 73),
# however more recent versions (version >= 74) must use "policies" to install extensions unattended
# (the news: https://blog.mozilla.org/addons/2019/10/31/firefox-to-discontinue-sideloaded-extensions/)
# (the new way for FF-version >= 74: https://github.com/mozilla/policy-templates/#extensions)
# (the old way for FF-version <= 73: https://extensionworkshop.com/documentation/publish/distribute-sideloading/#standard-extension-folders)
# The IDs of the extensions can be found after installing them and then navigating to "about:support" --> table "Add-Ons"
FF_EXTENSIONS_FOLDER="files/usr/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
mkdir -p "$FF_EXTENSIONS_FOLDER"
# uBlock
wget -O "$FF_EXTENSIONS_FOLDER/uBlock0@raymondhill.net.xpi" https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi
# Privacy Badger
wget -O "$FF_EXTENSIONS_FOLDER/jid1-MnnxcxisBPnSXQ@jetpack.xpi" https://addons.mozilla.org/firefox/downloads/file/3631723/privacy_badger-latest-an+fx.xpi
# Decentral Eyes
wget -O "$FF_EXTENSIONS_FOLDER/jid1-BoFifL9Vbdl2zQ@jetpack.xpi" https://addons.mozilla.org/firefox/downloads/file/3539177/decentraleyes-latest-an+fx.xpi
# NoScript
wget -O "$FF_EXTENSIONS_FOLDER/{73a6fe31-595d-460b-a920-fcc0f8843232}.xpi" https://addons.mozilla.org/firefox/downloads/file/3643224/noscript_security_suite-latest-an+fx.xpi

msg "combining files as tarball"
# make folder "files" a tarball and add it to the new ISOs root folder
tar -czvf "$TMPFOLDER/files.tgz" files/

#create ISO from folder with CD content
percent 50
msg "creating modified CD as new ISO"
#cp /usr/lib/ISOLINUX/isohdpfx.bin .
dd if="$BASEFOLDER/${ISO##*/}" bs=1 count=432 of=isohdpfx.bin
xorriso -as mkisofs -isohybrid-mbr isohdpfx.bin -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -o "$BASEFOLDER/modified_${ISO##*/}" "$TMPFOLDER"
rm -rf "$TMPFOLDER"
rm -rf "$TMPFOLDER2"
rm isohdpfx.bin

################################################################################
# prepare Virtualbox VM
################################################################################
percent 60
msg "Creating VM"
VBoxManage createvm --name "$MACHINENAME" --ostype "Debian_64" --register --basefolder "$BASEFOLDER"

percent 70
msg "configuring VM"
VBoxManage modifyvm "$MACHINENAME" --ioapic on
VBoxManage modifyvm "$MACHINENAME" --memory $(("$RAM_MB")) --vram 128
VBoxManage modifyvm "$MACHINENAME" --nic1 nat
VBoxManage modifyvm "$MACHINENAME" --cpus 4
VBoxManage modifyvm "$MACHINENAME" --graphicscontroller vboxsvga
VBoxManage modifyvm "$MACHINENAME" --audioout on
VBoxManage modifyvm "$MACHINENAME" --clipboard bidirectional

percent 80
msg "creating virtual disk"
VBoxManage createhd --filename "$BASEFOLDER/$MACHINENAME.vdi" --size $(("$HDD_MB")) --format VDI
VBoxManage storagectl "$MACHINENAME" --name "SATA Controller" --add sata --controller "IntelAhci" --hostiocache on
VBoxManage storageattach "$MACHINENAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium  "$BASEFOLDER/$MACHINENAME.vdi"

percent 90
msg "attaching ISO to VM"
VBoxManage storageattach "$MACHINENAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "$BASEFOLDER/modified_${ISO##*/}"     
VBoxManage modifyvm "$MACHINENAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none

################################################################################
# Run Virtualbox VM
################################################################################
VBoxManage startvm "$MACHINENAME" --type gui

#VBoxManage guestcontrol "TEST" --username bbuser --password %password% run --exe /usr/bin/firefox --putenv DISPLAY=:0 -- firefox --url http://startpage.com
msg "waiting for firefox to run in VM..."
while true; do
	VBoxManage guestcontrol "$MACHINENAME" --username "bbuser" --password "%password%" run --exe /bin/bash -- bash -c "pidof firefox-esr > /dev/null" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		break
	fi
	sleep 1
done

#change password
VBoxManage guestcontrol "$MACHINENAME" --username "bbuser" --password "%password%" run --exe /bin/bash -- bash -c "echo -e \"%password%\n$BBUSER_PASSWORD\n$BBUSER_PASSWORD\" | passwd bbuser"

percent 100
msg "Finished"
exec 3>&-
