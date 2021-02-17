#!/bin/bash

################################################################################
#
# BrowserBox, a VM with Firefox preinstalled and preconfigured
# 
# (c) 2020,2021 Tom Stöveken
# 
# License: GPLv3 ff
#
# Run the VM with QEMU, attach to the VM via SPICE protocol
#
################################################################################

HDD=$(zenity --file-selection --title="Select HDD image in qcow2 format")
if [ $? != 0 ] || [ ! -f "$HDD" ]; then
  zenity --error --text="No file selected or file not OK, leaving now..."
  exit 1
fi

qemu-system-x86_64 -smp 4 -machine accel=kvm -enable-kvm \
                   -hda "$HDD" \
                   -m "4096M" \
                   -name "BrowserBox" \
                   -spice unix,addr=/tmp/vm_spice.socket,disable-ticketing \
                   -device qxl-vga,id=video0,ram_size=268435456,vram_size=268435456,vram64_size_mb=0,vgamem_mb=64,max_outputs=1 \
                   -netdev user,id=n1 -device rtl8139,netdev=n1 \
                   -soundhw hda \
                   -device virtio-serial-pci,id=virtio-serial0,max_ports=16,bus=pci.0,addr=0x6 \
                   -chardev spicevmc,name=vdagent,id=vdagent \
                   -device virtserialport,nr=1,bus=virtio-serial0.0,chardev=vdagent,name=com.redhat.spice.0 \
                   -device ich9-usb-ehci1,id=usb \
                   -device ich9-usb-uhci1,masterbus=usb.0,firstport=0,multifunction=on \
                   -device ich9-usb-uhci2,masterbus=usb.0,firstport=2 \
                   -device ich9-usb-uhci3,masterbus=usb.0,firstport=4 \
                   -chardev spicevmc,name=usbredir,id=usbredirchardev1 \
                   -device usb-redir,chardev=usbredirchardev1,id=usbredirdev1 \
                   -chardev spicevmc,name=usbredir,id=usbredirchardev2 \
                   -device usb-redir,chardev=usbredirchardev2,id=usbredirdev2 \
                   -chardev spicevmc,name=usbredir,id=usbredirchardev3 \
                   -device usb-redir,chardev=usbredirchardev3,id=usbredirdev3 &

PID="$!"
remote-viewer -t "BrowserBox" spice+unix:///tmp/vm_spice.socket
kill "$PID"
