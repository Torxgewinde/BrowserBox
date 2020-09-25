#!/bin/bash

################################################################################
#
# BrowserBox, a VM with Firefox preinstalled and preconfigured
# 
# (c) 2020 Tom Stöveken
# 
# License: GPLv3 ff
#
# This file downloads an ISO image of Debian Netinstaller,
# remasters a new ISO that installs and configures the VM unattended.
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

ISO="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.5.0-amd64-netinst.iso"
BASEFOLDER="$(pwd)"

################################################################################
cd "$BASEFOLDER"

# required programs that must be installed manually, I assume coreutils is present anyway
REQUIRED_PROGRAMS=(
"zenity|zenity is missing, please install it with \"sudo apt install zenity\""
"wget|wget is missing, please install it with \"sudo apt install wget\""
"xorriso|xorriso is missing, please install with \"sudo apt install xorriso\""
)
SUCCESS="yes"
for i in "${REQUIRED_PROGRAMS[@]}"; do
	# we change $IFS here, but BASH restores it - so no need to save/restore it ourselves
	echo "$i" | while IFS="|" read PROG HINT; do

		hash $PROG > /dev/null 2>&1
		#To find out which package contains the command:
		#dpkg -S $(realpath $(which $PROG))

		if [ $? -ne 0 ]; then
			echo "$HINT"
			SUCCESS="no"
		fi
	done
done
if [ "$SUCCESS" == "no" ]; then
	exit 1
fi

# create a window with a progress bar, get texts through filedescriptor 3
exec 3> >(zenity --progress --title="Create VM" --percentage=0 --width=800 --no-cancel --auto-close)

# little helper function for the progress bar window
function msg {
	echo "# $@" >&3
}

function percent {
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

#unpack the ISO
percent 20
cd $BASEFOLDER || exit 1
TMPFOLDER=$(mktemp -d ISO_XXXX) || exit 1

msg "extracting ISO image to $TMPFOLDER"
xorriso -osirrox on -indev "$BASEFOLDER/${ISO##*/}" -extract / "$TMPFOLDER"

# change the CD contents
percent 30
msg "modifying CD content"
chmod -R +w "$TMPFOLDER"

cp postinst.sh "$TMPFOLDER/"

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
FF_EXTENSIONS_FOLDER="$BASEFOLDER/files/usr/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
mkdir -p "$FF_EXTENSIONS_FOLDER"

# uBlock
if [ ! -f "$FF_EXTENSIONS_FOLDER/uBlock0@raymondhill.net.xpi" ]; then
	wget -O "$FF_EXTENSIONS_FOLDER/uBlock0@raymondhill.net.xpi" https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi
fi

# Privacy Badger
if [ ! -f "$FF_EXTENSIONS_FOLDER/jid1-MnnxcxisBPnSXQ@jetpack.xpi" ]; then
	wget -O "$FF_EXTENSIONS_FOLDER/jid1-MnnxcxisBPnSXQ@jetpack.xpi" https://addons.mozilla.org/firefox/downloads/file/3631723/privacy_badger-latest-an+fx.xpi
fi

# Decentral Eyes
if [ ! -f "$FF_EXTENSIONS_FOLDER/jid1-BoFifL9Vbdl2zQ@jetpack.xpi" ]; then
	wget -O "$FF_EXTENSIONS_FOLDER/jid1-BoFifL9Vbdl2zQ@jetpack.xpi" https://addons.mozilla.org/firefox/downloads/file/3539177/decentraleyes-latest-an+fx.xpi
fi

# NoScript
if [ ! -f "$FF_EXTENSIONS_FOLDER/{73a6fe31-595d-460b-a920-fcc0f8843232}.xpi" ]; then
	wget -O "$FF_EXTENSIONS_FOLDER/{73a6fe31-595d-460b-a920-fcc0f8843232}.xpi" https://addons.mozilla.org/firefox/downloads/file/3643224/noscript_security_suite-latest-an+fx.xpi
fi

#modify syslinux to make it automatically run the text based installer
sed -i 's/timeout 0/timeout 20/g' "$TMPFOLDER/isolinux/isolinux.cfg"
sed -i 's/default installgui/default install/g' "$TMPFOLDER/isolinux/gtk.cfg"
sed -i 's/menu default//g' "$TMPFOLDER/isolinux/gtk.cfg"
sed -i 's/label install/label install\n\tmenu default/g' "$TMPFOLDER/isolinux/txt.cfg"
cp "$TMPFOLDER/isolinux/txt.cfg" "$TMPFOLDER/isolinux/txt.cfg.pre"

for LANG in "en" "de"; do
	case "$LANG" in
		de)
			cp "$TMPFOLDER/isolinux/txt.cfg.pre" "$TMPFOLDER/isolinux/txt.cfg"
			sed -i 's/append \(.*\)/append preseed\/file=\/cdrom\/preseed.cfg locale=de_DE.UTF-8 keymap=de language=de country=DE \1/g' "$TMPFOLDER/isolinux/txt.cfg"
			cp preseed_de.cfg "$TMPFOLDER/preseed.cfg"
			;;
		en)
			cp "$TMPFOLDER/isolinux/txt.cfg.pre" "$TMPFOLDER/isolinux/txt.cfg"
			sed -i 's/append \(.*\)/append preseed\/file=\/cdrom\/preseed.cfg locale=en_GB.UTF-8 keymap=en language=en country=GB \1/g' "$TMPFOLDER/isolinux/txt.cfg"
			cp preseed_en.cfg "$TMPFOLDER/preseed.cfg"
			;;
		*)
			echo "unknown language"
			exit 1
			;;
	esac
	
	msg "combining files as tarball"
	# make folder "files" a tarball and add it to the new ISOs root folder
	tar -czvf "$TMPFOLDER/files.tgz" files/
	
	#create ISO from folder with CD content
	percent 40
	msg "creating modified CD as new ISO"
	#cp /usr/lib/ISOLINUX/isohdpfx.bin .
	dd if="$BASEFOLDER/${ISO##*/}" bs=1 count=432 of=isohdpfx.bin
	mkdir "$BASEFOLDER/Releases"
	xorriso -as mkisofs -isohybrid-mbr isohdpfx.bin -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -o "$BASEFOLDER/Releases/BrowserBox_$LANG.iso" "$TMPFOLDER"

	percent 50
	msg "creating VirtualBox VM"
	bash VirtualBox/make.sh "$LANG" "$BASEFOLDER" "$BASEFOLDER/Releases/BrowserBox_$LANG.iso"
done

rm -rf "$TMPFOLDER"
rm isohdpfx.bin

percent 100
msg "Finished"
exec 3>&-
