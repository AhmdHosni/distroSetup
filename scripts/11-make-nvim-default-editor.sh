#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          set_nvim_as_default.sh
# Created:       Saturday, 24 January 2026 - 06:33 PM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:   This script sets Portable neovim as the default text editor for Gnome Desktop
#--------------------------------------------------------------------------------

##########
# 1. Paths
##########

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"
cache_sudo

# 1. Paths (Update NVIM_PATH to your actual SD card mount point)
STORAGE_DIR="/media/$USER/Storage"
NVIM_PATH="$STORAGE_DIR/Apps/neovim/nvim/nvim-linux.appimage"
ICON_DIR="$STORAGE_DIR/Pictures/icons" # update it to where you stored icons in your system
ICON_PATH="$ICON_DIR/neovim.svg"
DESKTOP_FILE="$HOME/.local/share/applications/nvim.desktop"

########
# Logic:
########

# one required package not installed by default in debian mininal install
# xdg-utils for xdg-mime (same package name for debian and arch)
install_package "xdg-utils" "xdg utils: A common desktop utilities contains xdg-open and xdg-mime"

# echo -e "${CYAN}==========================================${NC}"
# echo -e "${CYAN}    MAKING nvim THE DEFAULT EDITOR        ${NC}"
# echo -e "${CYAN}==========================================${NC}"
# echo ""

show_title "MAKING nvim THE DEFAULT EDITOR"

# add neovim portable .appimage to the path
#sudo ln -s /media/ahmdhosni/Storage/Apps/neovim/nvim/nvim-linux.appimage /usr/local/bin/nvim
echo -e "${YELLOW}${BOLD} Add neovim portable .appimage to the path${NC}"

sudo ln -s $NVIM_PATH /usr/local/bin/nvim

# 2. Download official Neovim icon
#mkdir -p "$ICON_DIR"
#echo "Downloading Neovim icon..."
#wget -O "$ICON_PATH" https://raw.githubusercontent.com

# 3. Create/Update Desktop Entry

echo -e "${YELLOW}${BOLD} Create/Update Desktop Entry${NC}"

cat <<EOF >"$DESKTOP_FILE"
[Desktop Entry]
Name=Neovim
GenericName=Text Editor
Comment=Edit text files
Exec=kitty -- "$NVIM_PATH" %F
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Utility;TextEditor;Development;
MimeType=text/plain;text/x-makefile;text/x-c++src;text/x-python;application/x-shellscript;
StartupNotify=true
StartupWMClass=gnome-terminal-server
EOF

# 4. Map text MIME types to Neovim
echo -e "${YELLOW}${BOLD}Mapping text MIME types to Neovim...${NC}"
TEXT_MIMES=$(grep '^text/' /usr/share/mime/types | sort -u)
for mime in $TEXT_MIMES; do
    xdg-mime default nvim.desktop "$mime"
done

# Additional common formats
xdg-mime default nvim.desktop application/json application/xml application/x-shellscript

# 5. Refresh system databases
update-desktop-database ~/.local/share/applications/
#gtk-update-icon-cache -f -t "$ICON_DIR"

echo -e "${GREEN}${BOLD}Done! Neovim now has an official icon and is the default for text files.${NC}"

#################
# Exit the script:
#################
exit 0
