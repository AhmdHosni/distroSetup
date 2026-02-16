#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          07-restore-gnome-settings.sh (REFINED)
# Created:       Wednesday, 04 February 2026 - 10:24 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Description:   Restores custom GNOME settings on a fresh install
#--------------------------------------------------------------------------------

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"
start_tmux
cache_sudo

##############
# Directories
##############

# Main directories
CONFIGS_DIR="$THIS_DIR/configs"
GNOME_SETTINGS_DIR="$THIS_DIR/gnome-settings"

# GNOME settings directories (distro-specific)
GNOME_SETTINGS_DEBIAN_DIR="$GNOME_SETTINGS_DIR/debian"
GNOME_SETTINGS_ARCH_DIR="$GNOME_SETTINGS_DIR/arch"

# GNOME settings backup files
GNOME_SETTINGS_DEBIAN_FILE="$GNOME_SETTINGS_DEBIAN_DIR/gnome_settings.bak"
GNOME_SETTINGS_ARCH_FILE="$GNOME_SETTINGS_ARCH_DIR/gnome_settings.bak"

# Extensions
EXTENSION_SOURCE_DEBIAN="$GNOME_SETTINGS_DEBIAN_DIR/extensions"
EXTENSION_SOURCE_ARCH="$GNOME_SETTINGS_ARCH_DIR/extensions"
EXTENSION_DEST="$HOME/.local/share/gnome-shell"

# Wallpapers
WALLPAPER_SOURCE_DIR="$GNOME_SETTINGS_DIR/backgrounds"
WALLPAPER_DEBIAN="$WALLPAPER_SOURCE_DIR/sunset.jpg"
WALLPAPER_ARCH="$WALLPAPER_SOURCE_DIR/samurai.jpg"
WALLPAPER_DEST="$HOME/.local/share/backgrounds"

# Icons
#ICONS_SOURCE_DIR="$CONFIGS_DIR/icons/pngs"
# ICONS_ZIP="$ICONS_SOURCE_DIR/breeze-extra.zip"
# ICONS_TARGET_PATH="breeze-extra-master/breeze-extra-dark"
# ICONS_THEME_CONFIG="$ICONS_SOURCE_DIR/index.theme"

FOLDER_ICONS_SOURCE_DIR="$CONFIGS_DIR/icons/pngs"
ICONS_URL="https://github.com/ahmdhosni/breeze-icons"
ICONS_DEST="$HOME/.local/share/icons"

# FireFox config
#FIREFOX_CONFIG_SOURCE_DIR="$CONFIGS_DIR/firefox/mozilla"

# Create destination directories
mkdir -p "$EXTENSION_DEST"
mkdir -p "$WALLPAPER_DEST"
mkdir -p "$ICONS_DEST"

########
# Logic
########

show_title "Restoring GNOME Settings" "Custom configurations and themes"

#########################
# COPY IMPORTANT CONFIGS
#########################

show_title "Copying Configuration Files"

# Copy kitty config
copy_folder "$CONFIGS_DIR/kitty" "$HOME/.config" "Kitty terminal configuration folder"

# Copy tmux config
copy_folder "$CONFIGS_DIR/tmux" "$HOME/.config" "Tmux terminal multiplexer configuration folder"

# Copy FireFox Config
#copy_folder "$FIREFOX_CONFIG_SOURCE_DIR" "$HOME/.config" "FireFox configuration folder"

#########################
# INSTALL ICON THEME
#########################

show_title "Installing Icon Theme"
#copy_folder "$ICONS_SOURCE_DIR" "$ICONS_DEST" "Copying custom icons"
git_clone "$ICONS_URL" "$ICONS_DEST" "Breeze Icons Dark: my favorite icon set on Gnome Dark themes"
# Fine-tune the extracted icon theme
if [ -d "$ICONS_DEST/breeze-extra-dark" ]; then
    #Remove apps folder (not needed)
    remove_folder "$ICONS_DEST/.git" "Removing .git folder from icon destination folder"
fi

# Copying custom folder and app icons.
copy_folder "$FOLDER_ICONS_SOURCE_DIR" "$ICONS_DEST" "Copying custom icons"

# Extract breeze-extra-dark icon theme from zip
#extract_from_zip "$ICONS_ZIP" "$ICONS_TARGET_PATH" "$ICONS_DEST" "Breeze Extra Dark icon theme" 1

# Fine-tune the extracted icon theme
# if [ -d "$ICONS_DEST/breeze-extra-dark" ]; then
#     echo ""
#     echo -e "${CYAN}Fine-tuning icon theme...${NC}"
#
#     # Copy custom index.theme
#     copy_file "$ICONS_THEME_CONFIG" "$ICONS_DEST/breeze-extra-dark" "Custom icon theme configuration"
#
#     # Remove apps folder (not needed)
#     remove_folder "$ICONS_DEST/breeze-extra-dark/apps" "Unnecessary apps folder from icon theme"
# fi

#########################
# DISTRO-SPECIFIC SETUP
#########################

if command -v apt-get &>/dev/null; then
    show_title "Applying Debian GNOME 48 Settings"

    # Copy GNOME extensions for Debian
    copy_folder "$EXTENSION_SOURCE_DEBIAN" "$EXTENSION_DEST" "GNOME extensions for Debian"

    # Copy Debian wallpaper
    copy_file "$WALLPAPER_DEBIAN" "$WALLPAPER_DEST" "Debian wallpaper (sunset.jpg)"

    # Load dconf settings for Debian GNOME 48
    load_dconf_settings "$GNOME_SETTINGS_DEBIAN_FILE" "Debian GNOME 48 settings (extensions, apps, desktop)" "force"

elif command -v pacman &>/dev/null; then
    show_title "Applying Arch GNOME 49 Settings"

    # Copy GNOME extensions for Arch
    copy_folder "$EXTENSION_SOURCE_ARCH" "$EXTENSION_DEST" "GNOME extensions for Arch"

    # Copy Arch wallpaper
    copy_file "$WALLPAPER_ARCH" "$WALLPAPER_DEST" "Arch wallpaper (samurai.jpg)"

    # Load dconf settings for Arch GNOME 49
    load_dconf_settings "$GNOME_SETTINGS_ARCH_FILE" "Arch GNOME 49 settings (extensions, apps, desktop)" "force"
fi

#################
# REQUIRE REBOOT
#################

show_title "Settings Restored!" "Reboot required to apply all changes"

echo -e "${GREEN}${BOLD}Summary:${NC}"
echo -e "${GREEN}  ✓ Configuration files copied${NC}"
echo -e "${GREEN}  ✓ Icon theme installed${NC}"
echo -e "${GREEN}  ✓ GNOME extensions copied${NC}"
echo -e "${GREEN}  ✓ Wallpaper installed${NC}"
echo -e "${GREEN}  ✓ GNOME settings loaded${NC}"
echo ""
echo -e "${YELLOW}${BOLD}A reboot is required to fully apply all changes.${NC}"
echo -e "${YELLOW}The system will reboot after the next script.${NC}"
echo ""

# Mark reboot as required
sudo touch /var/run/reboot-required

exit 0
