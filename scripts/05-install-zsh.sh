#!/bin/bash
#--------------------------------------------------------------------------------
# File:          2_install-zsh.sh
# Created:       Saturday, 31 January 2026 - 06:41 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:  This script installs zsh to the system including:
#                   1. Installing zsh, lsd, bat, fzf, zoxide, curl, git, wget, and xclip
#                   2. Copying my preffered .zshrc and global zenv with aliases and exports
#                   3. install and copies some Nerd Fonts to be used to show the icons
#                   4. changing the shell for both user and root to zsh
#                   5. removing old .bash and .profile files from both user and root
#--------------------------------------------------------------------------------

# this script runs as user and requires reboot when finished

#####################
# PREPARE DIRCTORIES:
#####################

# Get the directory where this script is located
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"
start_tmux
cache_sudo

# Sources
CONFIGS_SOURCE_FOLDER="$THIS_DIR/configs"
ZSH_CONFIGS_SOURCE_DIR="$CONFIGS_SOURCE_FOLDER/zsh"
FONTS_SOURCE_FOLDER="$CONFIGS_SOURCE_FOLDER/fonts"

# zshenv source file
ZSHenv_SOURCE_FILE="$ZSH_CONFIGS_SOURCE_DIR/zshenv"
# zshrc source file
ZSHrc_SOURCE_FILE="$ZSH_CONFIGS_SOURCE_DIR/.zshrc"
# p10k.zsh source file
P10K_SOURCE_FILE_USER="$ZSH_CONFIGS_SOURCE_DIR/.p10k-home.zsh"
P10K_SOURCE_FILE_ROOT="$ZSH_CONFIGS_SOURCE_DIR/.p10k-root.zsh"
# zshExtras source folder
ZSH_EXTRAS_SOURCE_FOLDER="$ZSH_CONFIGS_SOURCE_DIR/zshExtras"

# Destinations
# zshrc user destination folder
ZSHrc_DESTINATION_USER="$HOME/.config/zsh" && mkdir -p $ZSHrc_DESTINATION_USER
# zshrc root destination folder
ZSHrc_DESTINATION_ROOT="/root/.config/zsh" && sudo mkdir -p $ZSHrc_DESTINATION_ROOT

# zshenv global destination folder
ZSHenv_GLOBAL_DESTINATION_FOLDER="/etc/zsh"
# zshExtras global destination folder
ZSH_EXTRAS_GLOBAL_DESTINATION_FOLDER="/etc/zsh"
# fonts global destination folder
FONTS_GLOBAL_DESTINATION_FOLDER="/usr/share/fonts"
# global zinit
#ZINIT_GLOBAL_DESTINATION_FOLDER="$ZSH_EXTRAS_GLOBAL_DESTINATION_FOLDER/zinit" && sudo mkdir -p $ZINIT_GLOBAL_DESTINATION_FOLDER

# Making git directory at ~/.config/git to store git files
GIT_CONFIG_DIR_USER="$HOME/.config/git" && mkdir -p $GIT_CONFIG_DIR_USER
GIT_CONFIG_DIR_ROOT="/root/.config/git" && sudo mkdir -p $GIT_CONFIG_DIR_ROOT

##########################
# Calculate Total Packages
##########################

# Count active install_package calls in this script (excluding commented ones)
TOTAL_PACKAGES=$(grep -c "^install_package" "$0")
echo ""
echo -e "${CYAN}${BOLD}Total packages to process: ${TOTAL_PACKAGES}${NC}"

# echo -e "${CYAN}==========================================${NC}"
# echo -e "${CYAN}       INSTALLING zsh SHELL               ${NC}"
# echo -e "${CYAN}==========================================${NC}"
# echo ""

show_title "INSTALLING zsh SHELL"

######################
# INSTALLING PACKAGES:
#####################

# Installing zsh , and  some cool apps
# Installing zsh
install_package "zsh" "ZSH: A powerful shell with advanced features"
# Installing lsd
install_package "lsd" "LSDeluxe: Modern ls replacement with icons and colors"
# Installing bat
install_package "bat" "Bat: A cat clone with syntax highlighting"
# Installing fzf
install_package "fzf" "FZF: A command-line fuzzy finder"
# Installing zoxide
install_package "zoxide" "Zoxide: A smarter cd command"
# Installing xclip for terminal copy and paste to clipboard
install_package "xclip" "XClip: Command-line clipboard utility"
# Installing font-config
install_package "fontconfig" "provides available fonts to applications, also configure how fonts get rendered"
# install fonts-noto-emoji for colored emojies
install_package "fonts-noto-color-emoji" "Font: fonts-noto-color-emoji is a Noto  font for coloured emojies"

######################
## Copying zsh files :
######################

# echo ""
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo -e "${CYAN}${BOLD}  COPYING THE zsh CONFIG FILES          ${NC}"
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo ""

show_title "COPYING THE zsh CONFIG FILES"

# copying .zshrc file to user's config folder
copy_file "$ZSHrc_SOURCE_FILE" "$ZSHrc_DESTINATION_USER" "Custom .zshrc for root with zinit and p10k in case of GUI and kali's like zsh prompt for tty"

# copying .zshrc file to root's config folder
copy_file "$ZSHrc_SOURCE_FILE" "$ZSHrc_DESTINATION_ROOT" "Custom .zshrc for user with zinit and p10k for GUI and kali's like zsh prompt for tty"

# copying .p10k-home.zsh file to user's config folder
copy_file "$P10K_SOURCE_FILE_USER" "$ZSHrc_DESTINATION_USER" "My Prefferred p10k theme for Home, still need to create one for root"

# copying .p10k-root.zsh file to root's config folder
copy_file "$P10K_SOURCE_FILE_ROOT" "$ZSHrc_DESTINATION_ROOT" "My Prefferred p10k theme for Home, still need to create one for root"

# copying global zshenv file to /etc/zsh/
copy_file "$ZSHenv_SOURCE_FILE" "$ZSHenv_GLOBAL_DESTINATION_FOLDER" "Replacing global zshenv with this custom version"

# copying zshExtras folder to /usr/share/zsh/
copy_folder "$ZSH_EXTRAS_SOURCE_FOLDER" "$ZSH_EXTRAS_GLOBAL_DESTINATION_FOLDER" "ZshExtra folder with aliases, plugins and custom exports"

# Copy wget config to home config folder
copy_folder "$CONFIGS_SOURCE_FOLDER/wget" "$HOME/.config" "wget configuration folder"

#sudo mkdir -p /root/.cache
# Copy wget config to root config folder
copy_folder "$CONFIGS_SOURCE_FOLDER/wget" "/root/.config" "wget configuration folder"

######################
## Copying fonts :
######################

# echo ""
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo -e "${CYAN}${BOLD}  COPYING THE FONT FILES               ${NC}"
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo ""

show_title "COPYING THE FONT FILES"

# copy RobotMono Nerd Font to /usr/share/fonts/
copy_folder "$FONTS_SOURCE_FOLDER/RobotoMono" "$FONTS_GLOBAL_DESTINATION_FOLDER" "Copyinf Roboto Mono Nerd Font"

# copy Noto Kufi arabic font to /usr/share/fonts/
copy_folder "$FONTS_SOURCE_FOLDER/Noto-Kufi-arabic" "$FONTS_GLOBAL_DESTINATION_FOLDER" "Copying Noto Kufi Arabic"

# install truetype fonts to archlinux (needed for debian minimal - it shows terminal icons)
#if [ -x /usr/bin/pacman ]; then
# copy TrueType font to /usr/share/fonts/ including font awesomw (shows terminal icons )
copy_folder "$FONTS_SOURCE_FOLDER/truetype" "$FONTS_GLOBAL_DESTINATION_FOLDER" "Copying truetype fonts ( font awesome, nord, and dejavu ) to better show terminal icons"
#fi

# cahce the new fonts:
fc-cache -f

######################
## Changing the shell
######################

# echo ""
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo -e "${CYAN}${BOLD}  CHANGING THE SHELL TO zsh             ${NC}"
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo ""

show_title "CHANGING THE SHELL TO zsh"

# change shell of the user
echo -e "${YELLOW}${BOLD}\nChanging the shell to zsh for $USER ...${NC}"
sudo chsh -s $(which zsh) $USER
if [ $? -eq 0 ]; then echo -e "${GREEN}Shell changed successfully for ${USER} to zsh ${NC}"; else echo -e "${RED}Shell change failed for ${USER} ! ${NC}"; fi

# change shell of the root
echo -e "${YELLOW}${BOLD}\nChanging the shell to zsh for root ...${NC}"
sudo chsh -s $(which zsh) root
if [ $? -eq 0 ]; then echo -e "${GREEN}Shell changed successfully for root to zsh ${NC}"; else echo -e "${RED}Shell change failed for root ! ${NC}"; fi

# echo ""
# echo -e "${CYAN}${BOLD}==================================================${NC}"
# echo -e "${CYAN}${BOLD}  Grant zinit user/root shared Folder permissions  ${NC}"
# echo -e "${CYAN}${BOLD}===================================================${NC}"
# echo ""

# show_title "Grant zinit user/root shared Folder permissions"
#
# # CRITICAL FIX: Use a shared group that both user and root are members of
# # On most systems, 'users' group is better than 'staff'
# SHARED_GROUP="users"
#
# # Verify the group exists, create if it doesn't
# if ! getent group $SHARED_GROUP >/dev/null 2>&1; then
#     echo -e "${YELLOW}Creating $SHARED_GROUP group...${NC}"
#     sudo groupadd $SHARED_GROUP
# fi
#
# # Add both user and root to the shared group
# echo -e "${YELLOW}Adding $USER to $SHARED_GROUP group...${NC}"
# sudo usermod -aG $SHARED_GROUP $USER
#
# echo -e "${YELLOW}Adding root to $SHARED_GROUP group...${NC}"
# sudo usermod -aG $SHARED_GROUP root
#
# # Set ownership to root:users (more secure than user ownership)
# sudo chown -R root:$SHARED_GROUP $ZINIT_GLOBAL_DESTINATION_FOLDER
# if [ $? -eq 0 ]; then
#     echo -e "${GREEN}Ownership set to root:$SHARED_GROUP for $ZINIT_GLOBAL_DESTINATION_FOLDER${NC}"
# else
#     echo -e "${RED}Error: Failed to set ownership for $ZINIT_GLOBAL_DESTINATION_FOLDER${NC}"
# fi
#
# # Set permissions: owner=rwx, group=rwx, others=r-x
# # Using 2775 instead of 774:
# #   - The '2' sets the SGID bit (new files inherit group)
# #   - '775' gives rwx to owner and group, r-x to others
# sudo chmod -R 2775 $ZINIT_GLOBAL_DESTINATION_FOLDER
# if [ $? -eq 0 ]; then
#     echo -e "${GREEN}Permissions (2775) set for $ZINIT_GLOBAL_DESTINATION_FOLDER${NC}"
# else
#     echo -e "${RED}Error: Failed to set permissions for $ZINIT_GLOBAL_DESTINATION_FOLDER${NC}"
# fi
#
# # CRITICAL: Force group membership to take effect for current session
# # This ensures the user's current session recognizes the new group
# echo -e "${YELLOW}Refreshing group membership...${NC}"
# newgrp $SHARED_GROUP <<EOFGROUP
# echo -e "${GREEN}Group membership refreshed${NC}"
# EOFGROUP
#
# # Verify permissions
# echo -e "${CYAN}Verifying permissions:${NC}"
# ls -la $ZINIT_GLOBAL_DESTINATION_FOLDER

############################
## Removing old bash files :
############################

# echo ""
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo -e "${CYAN}${BOLD}  REMOVING OLD FILES .bash and .profile ${NC}"
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo ""

show_title "REMOVING OLD FILES .bash and .profile "

echo -e "${YELLOW}${BOLD}\nRemoving old bash files for $USER ...${NC}"
rm -vf $HOME/.bash*
if [ $? -eq 0 ]; then echo -e "${GREEN}.bash files removed successfully for ${USER} ${NC}"; else echo -e "${RED}.bash files removal failed for ${USER} ! ${NC}"; fi

rm -vf $HOME/.profile
if [ $? -eq 0 ]; then echo -e "${GREEN}.profile files removed successfully for ${USER} ${NC}"; else echo -e "${RED}.profile files removal failed for ${USER} ! ${NC}"; fi

echo -e "${YELLOW}${BOLD}\nRemoving old bash files for root ...${NC}"
sudo find /root -name ".bash*" -delete
if [ $? -eq 0 ]; then echo -e "${GREEN}.bash files removed successfully for root ${NC}"; else echo -e "${RED}.bash files removal failed for root !${NC}"; fi

sudo find /root -name ".profile" -delete
if [ $? -eq 0 ]; then echo -e "${GREEN}.profile file removed successfull for root ${NC}"; else echo -e "${RED}.proile file removal failed for root !${NC}"; fi

# echo ""
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo -e "${CYAN}${BOLD}  zsh Installation Complete!           ${NC}"
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo ""

show_title "zsh shell with preffered configs are ready for use" "just reboot to implement the new zsh shell"

sleep 1
################
# Require Reboot
################

sudo touch /var/run/reboot-required

##################
# Exit the Script
#################
exit 0
