#!/bin/bash

################################################################################
#
# 
#
################################################################################

MACHINENAME="TEST"
BASEFOLDER="$(pwd)"
RAM_MB=4096 
HDD_MB=10000
ISO="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.5.0-amd64-netinst.iso"


################################################################################
exec 3> >(zenity --progress --title="Create VM" --percentage=0 --width=800 --no-cancel)

function msg {
	echo "# $@" >&3
}

function percent {
	#echo "percent: $1"
	echo "$1" >&3
}

percent 0
msg "Creating VM"
VBoxManage createvm --name "$MACHINENAME" --ostype "Debian_64" --register --basefolder "$BASEFOLDER"

percent 10
msg "configuring VM"
VBoxManage modifyvm "$MACHINENAME" --ioapic on
VBoxManage modifyvm "$MACHINENAME" --memory $(("$RAM_MB")) --vram 128
VBoxManage modifyvm "$MACHINENAME" --nic1 nat

percent 20
msg "creating virtual disk"
VBoxManage createhd --filename "$BASEFOLDER/$MACHINENAME.vdi" --size $(("$HDD_MB")) --format VDI
VBoxManage storagectl "$MACHINENAME" --name "SATA Controller" --add sata --controller "IntelAhci" --hostiocache on
VBoxManage storageattach "$MACHINENAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium  "$BASEFOLDER/$MACHINENAME.vdi"

PERCENT_START=30
PERCENT_END=50
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

#unpack the ISO
cd $BASEFOLDER
TMPFOLDER=$(mktemp -d ISO_XXXX)
msg "extracting ISO image to $TMPFOLDER"
#7z x -bb0 -bd -o"$TMPFOLDER" "$BASEFOLDER/${ISO##*/}"
xorriso -osirrox on -indev "$BASEFOLDER/${ISO##*/}" -extract / "$TMPFOLDER"

# change the CD contents
percent 60
msg "modifying CD content"
chmod -R +w "$TMPFOLDER"

#modify syslinux to make it automatically run the text based installer
sed -i 's/timeout 0/timeout 100/g' "$TMPFOLDER/isolinux/isolinux.cfg"
sed -i 's/default installgui/default install/g' "$TMPFOLDER/isolinux/gtk.cfg"
sed -i 's/menu default//g' "$TMPFOLDER/isolinux/gtk.cfg"
sed -i 's/label install/label install\n\tmenu default/g' "$TMPFOLDER/isolinux/txt.cfg"
sed -i 's/append \(.*\)/append preseed\/file=\/cdrom\/preseed.cfg locale=de_DE.UTF-8 keymap=de language=de country=DE \1/g' "$TMPFOLDER/isolinux/txt.cfg"

cp preseed.cfg "$TMPFOLDER/preseed.cfg"

#create ISO from folder with CD content
percent 60
msg "creating modified CD as new ISO"
#cp /usr/lib/ISOLINUX/isohdpfx.bin .
dd if="$BASEFOLDER/${ISO##*/}" bs=1 count=432 of=isohdpfx.bin
#rm "$BASEFOLDER/${ISO##*/}"
xorriso -as mkisofs -isohybrid-mbr isohdpfx.bin -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -o "$BASEFOLDER/modified_${ISO##*/}" "$TMPFOLDER"
rm -rf "$TMPFOLDER"
rm isohdpfx.bin

percent 90
msg "attaching ISO to VM"
VBoxManage storageattach "$MACHINENAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "$BASEFOLDER/modified_${ISO##*/}"     
VBoxManage modifyvm "$MACHINENAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none

percent 100
msg "Finished"
sleep 1

exec 3>&-
