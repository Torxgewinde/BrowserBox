# BrowserBox
Do you want Firefox preconfigured for privacy and security? Then this is for you!

Installs and runs Firefox Browser inside a VM automatically and unattended. One command is sufficient to build the VM.

 - Based on Debian Buster, OpenBox and LightDM
 - Firefox-ESR
 - Extensions "Decentral Eyes", "Privacy Badger", "uBlock Origin", "NoScript" preinstalled
 - [arkenfox/user.js](https://github.com/arkenfox/user.js) preinstalled and customized
 - Wireguard preinstalled
 - Progress is visualized with Zenity


# Installation from scratch
The VM is created automatically, all you need to do is to run:

    bash createVM.sh

# Quick installation on a dedicated computer or other VMs like Qemu, VirtualPC, VM-Ware, ...
Download the most recent ISO-Image from releases and boot from it to start the unattended installation.

# Quick installation in VirtualBox
Download the most recent OVA-file from releases and double click it. VirtualBox will import the VM. If you would like to have the VirtualBox-Guest-Additions installed, insert the ISO-Image at startup into the virtual CD-ROM drive; it will be detected, automatically installed and trigger a restart to have them active from then on.

# Video
[<img src="https://raw.githubusercontent.com/wiki/Torxgewinde/BrowserBox/images/BrowserBox.gif">](https://raw.githubusercontent.com/wiki/Torxgewinde/BrowserBox/images/BrowserBox.mp4 "Video of script execution")
