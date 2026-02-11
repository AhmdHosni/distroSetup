#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          hide_unmounted_drives.sh
# Created:       Saturday, 31 January 2026 - 10:28 PM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:   This script hides unmounted drives based on their uuids in gui mode
#                But they still shown and can be accessed via the terminal
#--------------------------------------------------------------------------------

# This scripts runs as root, otherwize we will have a conflict and will not execute

# Don't add lib-functions here, it confilicts with the below order
# Dont't add cache_sudo as this is root (cached sudo will conflict)
# and no start_tmux as tmux is not needed for this script

# partitions to hide
ISOs_UUID="E2E69FB7E69F8A85"
VTOYEFI_UUID="E039-AD96"
Backups_UUID="60BAA09CBAA06FE8"
Windows_UUID="282AB86C2AB838A0"

echo -e "${YELLOW}${BOLD}Hiding mutiboot and iso partitions from the GUI ...${NC}"

sudo touch /etc/udev/rules.d/99-hide-disks.rules
# echo 'ENV{ID_FS_UUID}=="E2E69FB7E69F8A85", ENV{UDISKS_IGNORE}="1"' | sudo tee -a /etc/udev/rules.d/99-hide-disks.rules
#echo 'ENV{ID_FS_UUID}=="E039-AD96", ENV{UDISKS_IGNORE}="1"' | sudo tee -a /etc/udev/rules.d/99-hide-disks.rules
# ISOs partition
echo 'ENV{ID_FS_UUID}=="E2E69FB7E69F8A85", ENV{UDISKS_IGNORE}="1"' | sudo tee -a /etc/udev/rules.d/99-hide-disks.rules
# VTOYEFI partition
echo 'ENV{ID_FS_UUID}=="E039-AD96", ENV{UDISKS_IGNORE}="1"' | sudo tee -a /etc/udev/rules.d/99-hide-disks.rules
# Backups partition
echo 'ENV{ID_FS_UUID}=="60BAA09CBAA06FE8", ENV{UDISKS_IGNORE}="1"' | sudo tee -a /etc/udev/rules.d/99-hide-disks.rules
# Windows partition
echo 'ENV{ID_FS_UUID}=="282AB86C2AB838A0", ENV{UDISKS_IGNORE}="1"' | sudo tee -a /etc/udev/rules.d/99-hide-disks.rules
sudo udevadm control --reload-rules && sudo udevadm trigger

if [ $? -eq 0 ]; then echo -e "${GREEN}MultiBoot and ISOs partitions has been hidden from GUI successfully ${NC}"; else echo -e "${RED}Hiding MultiBoot and ISOs partitions failed ! ${NC}"; fi

#touch /var/run/reboot-required

#####################
# EXIT THE SCRIPT :
#####################
exit 0
