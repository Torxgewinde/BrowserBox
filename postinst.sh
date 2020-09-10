#!/bin/bash

#always exit cleanly, the virtualbox additions needed this quirk or otherwise it signaled an issue
function cleanup {
	exit 0
}
trap cleanup EXIT

#empty message of the day
echo -n "" > /etc/motd

#enable backports for wireguard in buster
echo 'deb http://deb.debian.org/debian buster-backports main contrib non-free' > /etc/apt/sources.list.d/buster-backports.list
apt update
apt install -y wireguard

#extract the tarball to the root directory, all extracted files will be owned by root:root
tar --directory=/ --strip-components=1 --no-same-owner --owner=root --group=root -xzf /tmp/files.tgz

#fix permissions and ownership
chown -R bbuser:bbuser /home/bbuser

#install VirtualBox
#wget -q https://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | apt-key add -
#echo 'deb https://download.virtualbox.org/virtualbox/debian contrib' > /etc/apt/sources.list.d/virtualbox.list
#apt-get update

#install VirtualBox Guest Additions
sh /root/VBoxLinuxAdditions.run

exit 0
