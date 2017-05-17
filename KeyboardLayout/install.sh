#!/bin/bash

XKB_PATH="/usr/share/X11/xkb"

EVDEV_FILE="$XKB_PATH/rules/evdev.xml"
TEMP_FILE="evdev.xml.tmp"

set -e

function command_exists()
{
    type "$1" &> /dev/null ;
}

if [[ $EUID -ne 0 ]] ; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# https://askubuntu.com/questions/482678/how-to-add-a-new-keyboard-layout-custom-keyboard-layout-definition

# Check if /usr/share/X11/xkb/symbols exists
if [ ! -d "$XKB_PATH/symbols" ] ; then
    echo "$XKB_PATH/symbols not found." 1>&2
    exit 1
fi
if [ ! -f "$EVDEV_FILE" ] ; then
    echo "$XKB_PATH/symbols not found." 1>&2
    exit 1
fi
if ! command_exists xmlstarlet ; then
    echo "xmlstarlet not found." 1>&2
    exit 1
fi
if ! command_exists dpkg-reconfigure ; then
    echo "dpkg-reconfigure not found." 1>&2
    exit 1
fi

# Backup the evdev file.
cp $EVDEV_FILE "evdev.xml.$(date "+%s").bak"

# Create the xkb entry.
cp sam "$XKB_PATH/symbols/sam"

# Delete existing "sam" entry in configuration.
xmlstarlet ed -P -d \
    '/xkbConfigRegistry/layoutList/layout[configItem/name = "sam"]' \
    $EVDEV_FILE > $TEMP_FILE
mv $TEMP_FILE $EVDEV_FILE

# Create configuration entry as follows.
# <xkbConfigRegistry version="1.1"> => layoutList => Add / Replace:
# <layout>
#     <configItem>
#         <name>sam</name>
#         <shortDescription>en</shortDescription>
#         <description>Sam - Colemak</description>
#         <languageList>
#             <iso639Id>eng</iso639Id>
#         </languageList>
#     </configItem>
#     <variantList>
#     </variantList>
# </layout>
 xmlstarlet ed -P \
     --subnode '/xkbConfigRegistry/layoutList' \
         --type elem -n layout \
     --subnode '/xkbConfigRegistry/layoutList/layout[last()]' \
         --type elem -n configItem \
     --subnode '/xkbConfigRegistry/layoutList/layout[last()]/configItem' \
         --type elem -n name -v sam \
     --subnode '/xkbConfigRegistry/layoutList/layout[last()]/configItem' \
         --type elem -n shortDescription -v "Sam - Colemak" \
     --subnode '/xkbConfigRegistry/layoutList/layout[last()]/configItem' \
         --type elem -n languageList \
     --subnode '/xkbConfigRegistry/layoutList/layout[last()]/configItem/languageList' \
         --type elem -n iso639Id -v eng \
     --subnode '/xkbConfigRegistry/layoutList/layout[last()]' \
         --type elem -n variantList \
    $EVDEV_FILE > $TEMP_FILE
mv $TEMP_FILE $EVDEV_FILE

# rm /var/lib/xkb/*.xkm
dpkg-reconfigure xkb-data

