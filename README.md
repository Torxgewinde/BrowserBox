# BrowserBox
Do you want Firefox preconfigured for privacy and security? Then this is for you!

Installs and runs Firefox Browser inside a VirtualBox VM automatically and unattended. One command is sufficient to build the VM.

 - Based on Debian Buster, OpenBox and LightDM
 - Firefox-ESR
 - Extensions "Decentral Eyes", "Privacy Badger", "uBlock Origin", "NoScript" preinstalled
 - [Arkenfox/gHacks user.js](https://github.com/arkenfox/user.js) preinstalled and customized
 - Wireguard preinstalled
 - VirtualBox Guest Additions are preinstalled to the VM
 - Progress is visualized with Zenity


# Installation from scratch
The VM is created automatically, all you need to do is to run:

    bash createVM.sh

# Installation in VirtualBox
Just download the most recent OVA-file from releases and double click it. VirtualBox will import the VM and you are done.

# Video
[<img src="https://raw.githubusercontent.com/wiki/Torxgewinde/BrowserBox/images/BrowserBox.gif">](https://raw.githubusercontent.com/wiki/Torxgewinde/BrowserBox/images/BrowserBox.mp4 "Video of script execution")
