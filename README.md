# BrowserBox
Do you want Firefox preconfigured for privacy and security? Then this is for you!

Installs and runs Firefox Browser inside a VM automatically and unattended. One command is sufficient to build the VM.

 - Based on Debian Buster, OpenBox and LightDM
 - Firefox-ESR
 - Extensions "Decentral Eyes", "Privacy Badger", "uBlock Origin", "NoScript" preinstalled
 - [arkenfox/user.js](https://github.com/arkenfox/user.js) preinstalled and customized
 - Progress is visualized with Zenity


# Installation from scratch
The VM is created automatically, all you need to do is to run:

    bash createVM.sh

# Quick installation in VirtualBox
If you like to use VirtualBox then download the most recent OVA-file from releases and double click it. VirtualBox will import the VM. VirtualBox-Guest-Additions are pre-installed, to update just insert the Guest-Additions-CD-ROM at startup and it will be detected, installed and trigger a restart to apply changes.

# Running it in QEMU (with SPICE)
If you like QEMU download the most recent QCOW2-file from releases and run the script QEMU/run-in-QEMU.sh as follows:

     bash QEMU/run-in-QEMU.sh
     
# Importing to VIRSH, Virtual Machine Manager
If you like VMM and VIRSH, download the most recent QCOW2-file and XML-file from releases and run the script QEMU/add-to-virsh.sh as follows:

     bash QEMU/add-to-virsh.sh

It will be defined in VMM and you can start the console from there. Since file locations can vary you will be prompted where the QCOW2 and XML file are located.

# Quick installation on a dedicated computer or other VMs VirtualPC, VM-Ware, ...
Download the most recent ISO-Image from releases and boot from it to start the unattended installation.

# Video
[<img src="https://raw.githubusercontent.com/wiki/Torxgewinde/BrowserBox/images/BrowserBox.gif">](https://raw.githubusercontent.com/wiki/Torxgewinde/BrowserBox/images/BrowserBox.mp4 "Video of script execution")
