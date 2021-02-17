#!/bin/bash

################################################################################
#
# BrowserBox, a VM with Firefox preinstalled and preconfigured
# 
# (c) 2020,2021 Tom Stöveken
# 
# License: GPLv3 ff
#
# Add the file to virsh (or Virtual Machine Manager)
#
################################################################################

HDD=$(zenity --file-selection --title="Select HDD image in qcow2 format")
if [ $? != 0 ] || [ ! -f "$HDD" ]; then
  zenity --error --text="No file selected or file not OK, leaving now..."
  exit 1
fi

XML=$(zenity --file-selection --title="Select Machine description in XML format")
if [ $? != 0 ] || [ ! -f "$XML" ]; then
  zenity --error --text="No file selected or file not OK, leaving now..."
  exit 1
fi

#temporary file for XML description
XML_MOD="$(mktemp --tmpdir=/tmp XML_XXXX)"

#debug message
echo "XML: $XML, HDD: $HDD, modified XML: $XML_MOD"

#replace placeholder of HDD image in XML file
sed -e "s#%virtual_harddisk%#$HDD#g" "$XML" > "$XML_MOD"

#define the machine but do not start it yet
virsh define "$XML_MOD"
