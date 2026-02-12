#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          update-system.sh
# Created:       Monday, 02 February 2026 - 01:40 PM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:   Perform System updates on Debian or Arch-linux Distributions
#--------------------------------------------------------------------------------

# This script runs as user so that we can have a tmux right progress panel
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"
start_tmux
cache_sudo

################
# SYSTEM UPDATE
################

# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo -e "${CYAN}${BOLD}  GNOME 48/49 Installation Script${NC}"
# echo -e "${CYAN}${BOLD}  Detected: ${DISTRO}${NC}"
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo ""

show_title "GNOME 48/49 Installation Script" "Detected: ${DISTRO}"

# install missing packages at arch
if [ -x /usr/bin/pacman ]; then
    install_package "which" "Installing 'which' which is an important package seems to be missing with arch base install"
fi

# update the system
system_update

#####################
# EXIT THE SCRIPT :
#####################
sleep 2
exit 0
