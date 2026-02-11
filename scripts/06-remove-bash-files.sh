#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          remove_bash_files.sh
# Created:       Monday, 09 February 2026 - 04:12 PM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:
#--------------------------------------------------------------------------------

################################
# Sourcing the functions library:
#################################
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"
cache_sudo

############################
## Removing old bash files :
############################

#ZSH_DESTINATION_DIR_USER="$HOME/.config/zsh" && mkdir -p $ZSH_DESTINATION_DIR_USER

# echo ""
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo -e "${CYAN}${BOLD}  REMOVING OLD FILES .bash and .profile ${NC}"
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo ""

# copying bash history to zsh history
#touch $ZSH_DESTINATION_DIR_USER/zsh_history
#cat $HOME/.bash_history | tee -a $ZSH_DESTINATION_DIR_USER/zsh_history

show_title "INSURE CLEANING UP AND REMOVING OLD FILES .bash and .profile "

# Remove .bashrc
remove_folder "$HOME/.bashrc" "Removing .bashrc file from $HOME"

# Remove .bash_history
remove_folder "$HOME/.bash_history" "Removing .bash_history file from $HOME"

# Remove .profile
remove_folder "$HOME/.profile" "Removing .profile file from $HOME"

# Remove .bashrc from root (the funtion auto detects sudo)
remove_folder "/root/.bashrc" "Removing .bashrc file from /root"

# Remove .bash_history from root
remove_folder "/root/.bash_history" "Removing .bash_history file from /root"

# Remove .profile from root
remove_folder "/root/.profile" "Removing .profile file from /root"

#echo -e "${YELLOW}${BOLD}\nRemoving old bash files for $USER ...${NC}"
#rm -vf $HOME/.bash*
#if [ $? -eq -1 ]; then echo -e "${GREEN}.bash files removed successfully for ${USER} ${NC}"; else echo -e "${RED}.bash files removal failed for ${USER} ! ${NC}"; fi

# rm -vf $HOME/.profile
# if [ $? -eq 0 ]; then echo -e "${GREEN}.profile files removed successfully for ${USER} ${NC}"; else echo -e "${RED}.profile files removal failed for ${USER} ! ${NC}"; fi
#

# Cleaning up Root bash files

show_title "Final check on Removing root's old bash files"
if [ -f /root/.bashrc]; then
    echo -e "${YELLOW}${BOLD}\nEnsure Removing old .bashrc file for root ...${NC}"
    sudo rm -vf /root/.bashrc
    if [ $? -eq 0 ]; then echo -e "${GREEN}.bashrc removed successfully for root ${NC}"; else echo -e "${RED}.bashrc removal failed for root !${NC}"; fi
fi

if [ -f /root/.bash]; then
    echo -e "${YELLOW}${BOLD}\nEnsure Removing old .bash_history file for root ...${NC}"
    sudo rm -vf /root/.bash_history
    if [ $? -eq 0 ]; then echo -e "${GREEN}.bash_history removed successfully for root ${NC}"; else echo -e "${RED}.bash_history removal failed for root !${NC}"; fi
fi

# Exit the script:
# ###############
exit 0
