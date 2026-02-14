#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          install_zsh_with_zinit.sh
# Created:       Monday, 26 January 2026 - 08:46 PM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:  This script installs global zinit and make it accessable for user and root
#--------------------------------------------------------------------------------

INSTALL_DIR="/etc/zsh/zshExtras/zinit"

if command -v apt-get &>/dev/null; then

    echo "Setting up shared Zinit directory for Debian..."
    # create a shared space where both your user and root can read/write Zinit data:
    # Create shared directory
    sudo mkdir -p $INSTALL_DIR
    # Set ownership to your user and a shared group
    sudo chown -R $USER:staff $INSTALL_DIR
    # Ensure group members can write (so root can write via its membership)
    sudo chmod -R 775 $INSTALL_DIR

    echo "✓ Directory created: $INSTALL_DIR"
    echo "✓ Ownership set to: $USER:wheel"
    echo "✓ Permissions set to: 775 with setgid"

# Link for Root Access
# --------------------
# To ensure root uses the exact same configuration and shared downloads:
# 1. Link the ZDOTDIR: Root needs to know where to find the config.
# sudo mkdir -p /root/.config/zsh
# sudo ln -sf "$HOME/.config/zsh/.zshrc" /root/.config/zsh/.zshrc
# Handle the P10k Config: If you configure P10k as a user, link that too so root looks the same:
# sudo ln -sf "$HOME/.config/zsh/.p10k.zsh" /root/.config/zsh/.p10k.zsh

elif command -v pacman &>/dev/null; then

    # Method 1: Using 'wheel' group (recommended for Arch Linux)
    # ------------------------------------------------------------
    # Most Arch users are already in the 'wheel' group, and root has access to it

    echo "Setting up shared Zinit directory for Arch Linux..."

    # Create shared directory
    sudo mkdir -p "$INSTALL_DIR"

    # Set ownership to your user and the wheel group
    sudo chown -R "$USER:wheel" "$INSTALL_DIR"

    # Set permissions: owner and group can read/write/execute
    sudo chmod -R 775 "$INSTALL_DIR"

    # Ensure the setgid bit is set so new files inherit the group
    sudo chmod -R g+s "$INSTALL_DIR"

    echo "✓ Directory created: $INSTALL_DIR"
    echo "✓ Ownership set to: $USER:wheel"
    echo "✓ Permissions set to: 775 with setgid"

fi

# exit the script
#################
exit 0
