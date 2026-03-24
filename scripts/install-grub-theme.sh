#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          install-theme.sh
# Created:       Thursday, 19 February 2026 - 02:04 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:    This script installs arch silence theme to grub boot menu
#--------------------------------------------------------------------------------

# Define the file paths
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" ## this dir path (where we are)
GRUB_THEMES_DIR="/boot/grub/themes/"                     ## where the system's grub themes folder are (/boot/grub/themes/)
GRUB_FILE="/etc/default/grub"                            ## where the theme configuration is (/etc/default/grub)

SOURCE_DIR="$THIS_DIR/configs/grub/theme" ## Grub theme source dir

copyThemeFiles() {

    THEME_DIR="$GRUB_THEMES_DIR/silence"

    if [ -d $GRUB_THEMES_DIR ]; then
        sudo rm -vfr $GRUB_THEMES_DIR/*
        sudo mkdir -p $THEME_DIR
    else
        sudo mkdir -p $THEME_DIR
    fi

    sudo cp -vfr $SOURCE_DIR/progress_bar $THEME_DIR
    sudo cp -vf $SOURCE_DIR/dejavu_bold_14.pf2 $THEME_DIR
    sudo cp -vf $SOURCE_DIR/dejavu_mono_12.pf2 $THEME_DIR
    sudo cp -vf $SOURCE_DIR/help_bar.png $THEME_DIR
    sudo cp -vf $SOURCE_DIR/theme.txt $THEME_DIR
    if command -v apt-get &>/dev/null; then
        sudo cp -vf $SOURCE_DIR/debian.png $THEME_DIR/logo.png
    elif command -v pacman &>/dev/null; then
        sudo cp -vf $SOURCE_DIR/arch.png $THEME_DIR/logo.png
    fi

}

## adding system editor to sudoers so that i can set a custom system editor.
echo 'Defaults env_keep += "EDITOR VISUAL SYSTEMD_EDITOR"' | sudo tee /etc/sudoers.d/editors && sudo chmod 440 /etc/sudoers.d/editors

copyThemeFiles

if command -v apt-get >/dev/null; then
    echo "GRUB_THEME='/boot/grub/themes/silence/theme.txt'" | sudo tee -a $GRUB_FILE
    sudo update-grub
elif command -v pacman >/dev/null; then
    sudo sed -i 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/silence/theme.txt"|' "$GRUB_FILE"
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

exit 0

# # Copy the theme folder to grub themes folder
# if [ -d $GRUB_THEMES_DIR/arch ]; then
#     sudo rm -vrf $GRUB_THEMES_DIR/arch/*
#     sudo cp -vfr $THIS_DIR/theme/progress_bar $GRUB_THEMES_DIR/arch
#     sudo cp -vf $THIS_DIR/theme/dejavu_bold_14.pf2 $GRUB_THEMES_DIR/arch
#     sudo cp -vf $THIS_DIR/theme/dejavu_mono_12.pf2 $GRUB_THEMES_DIR/arch
#     sudo cp -vf $THIS_DIR/theme/help_bar.png $GRUB_THEMES_DIR/arch
#     sudo cp -vf $THIS_DIR/theme/theme.txt $GRUB_THEMES_DIR/arch
#     sudo cp -vf $THIS_DIR/theme/arch.png $GRUB_THEMES_DIR/arch/logo.png
# else
#     sudo mkdir -p $GRUB_THEMES_DIR/arch
#     sudo cp -vfr $THIS_DIR/theme/progress_bar $GRUB_THEMES_DIR/arch
#     sudo cp -vf $THIS_DIR/theme/dejavu_bold_14.pf2 $GRUB_THEMES_DIR/arch
#     sudo cp -vf $THIS_DIR/theme/dejavu_mono_12.pf2 $GRUB_THEMES_DIR/arch
#     sudo cp -vf $THIS_DIR/theme/help_bar.png $GRUB_THEMES_DIR/arch
#     sudo cp -vf $THIS_DIR/theme/theme.txt $GRUB_THEMES_DIR/arch
#     sudo cp -vf $THIS_DIR/theme/arch.png $GRUB_THEMES_DIR/arch/logo.png
#
# fi

# Use sed to find the line starting with #GRUB_THEME and replace it
# -i: edits the file in-place
# s: substitute command
# sudo sed -i 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/arch/theme.txt"|' "$GRUB_FILE"
#
# # Update GRUB to apply changes
# # Use update-grub for Debian/Ubuntu or grub-mkconfig for Arch/Fedora
# if command -v update-grub >/dev/null; then
#     sudo update-grub
# else
#     sudo grub-mkconfig -o /boot/grub/grub.cfg
# fi
#
