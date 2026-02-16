#!/bin/bash
#--------------------------------------------------------------------------------
# File:          install-gnome.sh
# Created:       Saturday, 31 January 2026 - 06:41 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:  This script installs gnome Desktop Manager for Debian and Arch including:
#                   1. Gnome core packages and most Essentials apps
#                   2. Installs kitty instead of the default gnome terminal
#                   3. Installs tmux for terminal multiplexing
#                   4. Adding custom configs for kitty, tmux and wget
#--------------------------------------------------------------------------------

# 2026 Full GNOME 48/49 Application Installer for Debian 13 (Trixie)
# This script runs as user and requires reboot once finished.

#####################
# PREPARE DIRCTORIES:
#####################

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"
start_tmux
cache_sudo

# echo ""
# echo -e "${CYAN}==========================================${NC}"
# echo -e "${CYAN}       INSTALLING GNOME ON $DISTRO        ${NC}"
# echo -e "${CYAN}==========================================${NC}"
# echo ""

##########################
# Calculate Total Packages
##########################

# Count active install_package_no_recommendations calls in this script (excluding commented ones)
TOTAL_PACKAGES=$(grep -c "^install_package_no_recommendations" "$0")
echo ""
echo -e "${CYAN}${BOLD}Total packages to process: ${TOTAL_PACKAGES}${NC}"

show_title "INSTALLING GNOME PACKAGES ON $DISTRO"

#########################
# Clean the debian system:
#########################
#show_title "Removing old unused system packages"
system_clean

#########################
# INSTALL GNOME PACKAGES:
#########################
show_title "INSTALLING CORE PACKAGES"

# --- THE DESKTOP FRAMEWORK ---
#show_title "Installing Desktop Framework"
install_package_no_recommendations "gnome-shell" "The Shell: The main UI including the top bar, dash, and activities overview"
install_package_no_recommendations "gnome-session" "Session Manager: Logic that starts the desktop environment and saved apps"

# --- SYSTEM MANAGEMENT & DISK TOOLS ---
#show_title "Installing System Management and Disk tools"
install_package_no_recommendations "gnome-control-center" "Settings: The central hub for Wi-Fi, Bluetooth, Displays, and Users"
install_package_no_recommendations "nautilus" "Files: The official file manager for browsing folders and drives"
install_package_no_recommendations "gnome-system-monitor" "System Monitor: View CPU/RAM usage and kill unresponsive processes"

# Commented out packages (uncomment if needed):
#install_package_no_recommendations "gnome-software" "Software: The graphical app store for Flatpaks and packages"
#install_package_no_recommendations "thunar" "Alternative file manager"
#install_package_no_recommendations "baobab" "Disk Usage Analyzer: Visualizes folder sizes to help clear disk space"
#install_package_no_recommendations "gnome-disk-utility" "Disks: Manage partitions, format USB drives, and check drive health"
#install_package_no_recommendations "gnome-logs" "Logs: A viewer for system events and error messages for troubleshooting"

# --- MODERN 2026 CORE MEDIA & DOCUMENT APPS ---
#show_title "Installing Core Media and Document Apps"
#install_package_no_recommendations "eog" "Eye of GNOME: Classic image viewer with reliable performance"
install_package_no_recommendations "snapshot" "Snapshot: The modern camera app for taking photos and recording video clips"

# Commented out packages (uncomment if needed):
#install_package_no_recommendations "ptyxis" "Terminal: The modern container-aware terminal emulator for GNOME 48/49"
# Installing kitty instead of ptyxis
install_package "kitty" "Modern GPU-based terminal emulator with advanced features"

#install_package_no_recommendations "papers" "Papers: The high-performance 2026 replacement for Evince PDF viewer"
#install_package_no_recommendations "showtime" "Showtime: The minimalist video player that replaced Totem in GNOME 49"
install_package_no_recommendations "loupe" "Loupe: The modern, gesture-friendly image viewer with HDR support"
#install_package_no_recommendations "decibels" "Decibels: A specialized app for previewing single audio files quickly"

# --- PRODUCTIVITY & DAILY UTILITIES ---
#show_title "Installing Productivity and Daily Utilities"
install_package_no_recommendations "gnome-calculator" "Calculator: Support for basic, scientific, and financial calculations"
install_package_no_recommendations "gnome-calendar" "Calendar: Schedule management with support for online accounts (Google/Nextcloud)"

# Commented out packages (uncomment if needed):
#install_package_no_recommendations "gnome-text-editor" "Text Editor: The modern, tabbed replacement for Gedit with auto-save"
#install_package_no_recommendations "gnome-clocks" "Clocks: World clocks, alarms, stopwatches, and timers"
#install_package_no_recommendations "gnome-weather" "Weather: Real-time forecasts and conditions integrated into the shell"
#install_package_no_recommendations "gnome-maps" "Maps: Browse maps, search for POIs, and get directions using OpenStreetMap"
#install_package_no_recommendations "epiphany-browser" "Web: The official GNOME browser focused on simplicity and privacy"
#install_package_no_recommendations "simple-scan" "Document Scanner: A utility to scan documents directly to PDF or JPG"

# --- ACCESSORIES & FONTS ---

# Commented out packages (uncomment if needed):
#install_package_no_recommendations "gnome-characters" "Characters: Easily find and copy emojis and special Unicode symbols"
#install_package_no_recommendations "gnome-font-viewer" "Font Viewer: Preview and install system or user fonts"
#install_package_no_recommendations "gnome-music" "Music: A library manager and player for locally stored audio files"
#install_package_no_recommendations "vlc" "VLC: Versatile media player for both music and videos"
#install_package_no_recommendations "gnome-connections" "Connections: A remote desktop client for VNC and RDP protocols"

# --- ADVANCED TOOLS & VIRTUALIZATION ---

# Commented out packages (uncomment if needed):
#install_package_no_recommendations "gnome-boxes" "Boxes: Simple tool for creating and managing Virtual Machines (VMs)"
#install_package_no_recommendations "manuals" "Manuals: The modern developer documentation viewer that replaced Devhelp"
#show_title "Installing Desktop Utilitites"

#install_package_no_recommendations "gnome-shell-extension-manager" "Extension Manager: A native tool to install and update desktop extensions"

# --- NETWORKING & X11 COMPATIBILITY ---

# # Handle NetworkManager naming differences
# if [ "$DISTRO" = "debian" ]; then
#     install_package_no_recommendations "network-manager" "NetworkManager: The engine that powers the Wi-Fi and Ethernet icons"
# else
#     install_package_no_recommendations "networkmanager" "NetworkManager: The engine that powers the Wi-Fi and Ethernet icons"
# fi
#
#install_package_no_recommendations "xorg-xwayland" "XWayland: Ensures older apps (X11) still work on the new Wayland display server" || install_package_no_recommendations "xwayland" "XWayland: Ensures older apps (X11) still work on the new Wayland display server"

# Set system to boot into the graphical interface
#sudo systemctl set-default graphical.target

#################
# Extra packages:
#################

show_title "INSTALLING EXTRA PACKAGES"

install_package "xdg-utils" "xdg utils: A common desktop utilities contains xdg-open and xdg-mime"

# Installing gnome-tewaks
install_package "gnome-tweaks" "Tweaks: Unlocks advanced settings for themes, fonts, and window behavior"

# Installing curl
install_package "curl" "Curl: Command-line tool for transferring data with URLs"
# Installing git
install_package "git" "Git: Distributed version control system"
# Installing wget
install_package "wget" "Wget: Network downloader"
# Installing timeshift
install_package "timeshift" "TimeShift: revert back at any point of time with your distro"

#####################################################################
# SPICIFIC DISTRO PACKAGES PLUS REQUIREMENT FOR SYSTEM MONITOR NEXT :
#####################################################################

# install required dependences for system monitor next extension
if command -v apt-get &>/dev/null; then
    # Debian spicific package names
    install_package_no_recommendations "gdm3" "Display Manager: Handles the login screen and user session switching"
    #install_package_no_recommendations "firefox-esr" "A web browser way better than gnome default browser"
    # installing firefox from source
    install_package "gnome-shell-extension-manager" "Extension Manager: A native tool to install and update desktop extensions"
    # for system monitor next extension
    install_package "gir1.2-gtop-2.0" "GObject introspection data for libgtop"
    install_package "gir1.2-nm-1.0" "GObject introspection data for NetworkManager"
    install_package "gir1.2-clutter-1.0" "GObject introspection data for Clutter"
    install_package "chrome-gnome-shell" "Gnome browser connector is a dependency for extension install through firefox"
    # install_package_no_recommendations "libarchive-tools" "LibaArchive-tools: gnome Archiving tools (badunzip, bsdtar ...etc). A utility for compressing and decompressing"
    # Run the Firefox install script
    if bash "$THIS_DIR/07b-installFirefox.sh"; then
        echo -e "${GREEN}✓ Firefox latest version is installed${NC}"
    else
        echo -e "${RED}✗ attempt for the installaion of latest version of Firefox failed${NC}"
        echo -e "${YELLOW}  You can install it manually later${NC}"
    fi

elif command -v pacman &>/dev/null; then
    # Arch spicific package names
    install_package_no_recommendations "gdm" "Display Manager: Handles the login screen and user session switching"
    sudo systemctl enable gdm
    install_package_no_recommendations "firefox" "A web browser way better than gnome default browser"
    install_package_no_recommendations "extension-manager" "Extension Manager: A native tool to install and update desktop extensions through firefox"
    install_package_no_recommendations "gnome-browser-connector" "Gnome browser connector is a dependency for extension install"
    # for system monitor next extension
    install_package_no_recommendations "libgtop" "GObject introspection data for libgtop"
    # install_package_no_recommendations "libarchive" "LibArchive: gnome archiving tool,(badunzip, bsdtar ...etc). A utility for compressing and decompressing"
    #install_package_no_recommendations "clutter" "GObject introspection data for Clutter"

fi

show_title "Installation Complete!" "GNOME 48/49 is ready for use."
# echo -e "${GREEN}GNOME 48/49 is ready for use.${NC}"

# no reboot is required here, we will reboot after applying the custom settings (after next script)
# Remove reboot flag if exists
sudo rm -f /var/run/reboot-required

##################
# EXIT THE SCRIPT:
##################

exit 0
