#!/usr/bin/env bash

# It's recommended that `raspi-config` tool is up to date before running the commands below

# Please run `dpkg-reconfigure tzdata` if you wish to reconfigure timezone. 
# Refer to 'TZ database name' column in the following link (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List):
echo "** Set up timezone to match US Eastern timezone **"
raspi-config nonint do_change_timezone "US/Eastern"

# Please run `dpkg-reconfigure keyboard-configuration` if you wish to change keyboard layout
# Please see here on how to update keyboard layout: https://wiki.archlinux.org/index.php/Linux_console/Keyboard_configuration#Listing_keymaps
echo "** Set the keyboard layout to US English keyboard **"
raspi-config nonint do_configure_keyboard us

echo "** Change to give the least amount of memory made available to the GPU (e.g. 16/32/64/128/256) **"
raspi-config nonint do_memory_split 16

echo "** Ensures that all of the SD card storage is available to the OS **"
raspi-config --expand-rootfs

# Please run `dpkg-reconfigure locales` if you wish to change locale later
echo "** Set up language and regional settings to match your location **"
raspi-config nonint do_change_locale en_US.UTF-8

# For Ansible to skip the script at the subsequent run
touch /script-raspi-config_has_ran.true

# Reboot is strongly recommended after the above commands are completed
