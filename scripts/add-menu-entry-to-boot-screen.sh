#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          add-menu-entry-to-boot-screen.sh
# Created:       Wednesday, 18 February 2026 - 05:37 PM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:      This script add boot menuentry for:
#                       1- Terminal Only
#                       2- Reboot
#                       3- Power off
#                   for both debian 13 and arch-linux boot screen.
#--------------------------------------------------------------------------------

# Shared functions for the system utilities
add_system_utils() {
    cat <<'EOF' | sudo tee -a /etc/grub.d/40_custom

menuentry 'System Reboot' --class restart {
    reboot
}

menuentry 'System Power Off' --class shutdown {
    halt
}
EOF
}

if command -v apt-get &>/dev/null; then
    echo "Detected Debian-based system."
    add_system_utils
    sudo update-grub

elif command -v pacman &>/dev/null; then
    KERNEL_RELEASE=$(uname -r)

    if [[ "$KERNEL_RELEASE" == *"-lts"* ]]; then
        echo "Detected Arch LTS. Adding LTS Terminal & Utils..."
    elif [[ "$KERNEL_RELEASE" == *"-zen"* ]]; then
        echo "Detected Arch Zen. Adding Zen Terminal & Utils..."
    fi

    add_system_utils
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

exit 0
