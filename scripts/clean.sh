#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          archClean.sh
# Created:       Monday, 23 February 2026 - 09:43 PM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:   A script to clean debian or archlinux
#--------------------------------------------------------------------------------

# --- Universal Safe Maintenance Script (Arch/Debian) ---

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)."
    exit
fi

if command -v pacman &>/dev/null; then
    echo "--- Arch Linux detected ---"

    # 1. Remove orphans
    ORPHANS=$(pacman -Qdtq)
    if [ -n "$ORPHANS" ]; then
        pacman -Rns $ORPHANS --noconfirm
    fi

    # 2. Clean cache (requires pacman-contrib for paccache)
    if command -v paccache &>/dev/null; then
        paccache -r    # Keep last 3
        paccache -ruk0 # Remove uninstalled
    else
        pacman -Sc --noconfirm
    fi

elif command -v apt &>/dev/null; then
    echo "--- Debian/Ubuntu detected ---"

    # 1. Update lists
    apt update

    # 2. Remove unused deps and purge configs
    apt autoremove --purge -y

    # 3. Clean package archives
    apt autoclean
    apt clean

    # 4. Purge residual configs (packages in 'rc' state)
    CONF_PKGS=$(dpkg -l | grep "^rc" | awk '{print $2}')
    [ -n "$CONF_PKGS" ] && apt purge -y $CONF_PKGS

else
    echo "Unsupported distribution."
    exit 1
fi

# --- Common Cleanup (Both Systems) ---
echo "--- Performing general cleanup ---"

# Vacuum logs to 1 week
journalctl --vacuum-time=7d

# Clean Flatpak if installed
if command -v flatpak &>/dev/null; then
    flatpak uninstall --unused -y
fi

echo "Cleanup finished successfully!"

# exit the script
exit 0
