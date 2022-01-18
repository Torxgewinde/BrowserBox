#!/bin/bash

################################################################################
#
# BrowserBox, a VM with Firefox preinstalled and preconfigured
# 
# (c) 2020,2021 Tom Stöveken
# 
# License: GPLv3 ff
#
# Create the VirtualBox VM, this script executes VirtualBox specific commands
# In the end it generates OVF-packages, e.g. OVA files
#
################################################################################

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

# generate a random password and keep a record in the description
BBUSER_PASSWORD="$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c10)"
echo "generated password: $BBUSER_PASSWORD"
VBoxManage modifyvm "$MACHINENAME" --description "Password for user \"bbuser\" is \"$BBUSER_PASSWORD\""

VBoxManage createhd --filename "$BASEFOLDER/VirtualBox/$MACHINENAME.vdi" --size $(("$HDD_MB")) --format VDI
VBoxManage storagectl "$MACHINENAME" --name "SATA Controller" --add sata --controller "IntelAhci" --hostiocache on
VBoxManage storageattach "$MACHINENAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium  "$BASEFOLDER/VirtualBox/$MACHINENAME.vdi"

VBoxManage storageattach "$MACHINENAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "$ISO"     
VBoxManage modifyvm "$MACHINENAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none

################################################################################
# Run Virtualbox VM
################################################################################
VBoxManage startvm "$MACHINENAME" --type gui

# wait until the netinstaller ISO is ejected
# alternatively check for this: "SATA Controller-1-0"="emptydrive"
while true; do
  sleep 1
  VBoxManage showvminfo --machinereadable "$MACHINENAME" | grep "\"SATA Controller-IsEjected\"=\"on\""
  
  if [ $? -eq 0 ]; then
    echo "CD ejected from $MACHINENAME"
    break
  fi
done

#################################################################################
# Install Guest-Additions
#################################################################################

# if guest-additions-iso are already installed to this host machine this medium works
#VBoxManage storageattach "$MACHINENAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium additions
# but we better be sure to have the ISO downloaded ourselves
VBoxManage storageattach "$MACHINENAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "${GUESTISO##*/}"

#################################################################################
# Wait till firefox-esr process is active
# injecting commands into the VM only works if guest additions are running
#################################################################################
while true; do
	VBoxManage guestcontrol "$MACHINENAME" --username "bbuser" --password "%password%" run --exe /bin/bash -- bash -c "pidof firefox-esr > /dev/null" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		break
	fi
	sleep 1
done

#################################################################################
# set password, power off
#################################################################################
#add user to vboxsf group, this is only useful for VirtualBox
VBoxManage guestcontrol "$MACHINENAME" --username "bbuser" --password "%password%" run --exe /bin/bash -- bash -c "sudo adduser bbuser vboxsf"

#change password inside VM to a random password
VBoxManage guestcontrol "$MACHINENAME" --username "bbuser" --password "%password%" run --exe /bin/bash -- bash -c "echo -e \"%password%\n$BBUSER_PASSWORD\n$BBUSER_PASSWORD\" | passwd bbuser"

# shutdown appliance
VBoxManage guestcontrol "$MACHINENAME" --username "bbuser" --password "$BBUSER_PASSWORD" run --exe /bin/bash -- bash -c "sleep 10 && sudo /sbin/shutdown -h now"

# wait until VM is powered off
while true; do
  sleep 1
  VBoxManage showvminfo --machinereadable "$MACHINENAME" | grep "VMState=\"poweroff\""
  
  if [ $? -eq 0 ]; then
    echo "$MACHINENAME powered down"
    break
  fi
done

#################################################################################
# export appliance
#################################################################################
VBoxManage export "$MACHINENAME" --output "$BASEFOLDER/Releases/$MACHINENAME.ova" --ovf10 \
  --options manifest,nomacs \
  --vsys 0 \
  --vmname "$MACHINENAME" \
  --product "BrowserBox" \
  --producturl "https://github.com/Torxgewinde/BrowserBox" \
  --description "Password for user \"bbuser\" is \"$BBUSER_PASSWORD\""
