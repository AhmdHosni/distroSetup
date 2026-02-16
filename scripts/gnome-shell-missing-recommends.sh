#!/bin/bash
#--------------------------------------------------------------------------------
# File:          gnome-shell-missing-recommends.sh
# Description:   Manually installs the recommended packages for gnome-shell and
#                gnome-session that are skipped when using --no-install-recommends.
#
# WHY THIS EXISTS:
#   When installing gnome-shell with --no-install-recommends, apt skips 12
#   recommended packages. Some of these are essential for a functional desktop
#   (e.g. evolution-data-server for calendar integration) while others are only
#   needed for specific hardware (e.g. bolt for Thunderbolt docks).
#
#   This snippet lets you cherry-pick exactly what you need.
#
# USAGE:
#   Insert this section in your install-gnome.sh script right AFTER
#   the gnome-shell and gnome-session install lines.
#
# NOTE:
#   gnome-session has NO recommended packages (only Depends and Suggests),
#   so using --no-install-recommends on it has zero side effects.
#   All entries below are from gnome-shell's Recommends only.
#--------------------------------------------------------------------------------

#####################
# Functions Library :
#####################

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"
start_tmux
cache_sudo

##########################
# Calculate Total Packages
##########################

# Count active install_package calls in this script (excluding commented ones)
TOTAL_PACKAGES=$(grep -c "^install_package" "$0")
echo ""
echo -e "${CYAN}${BOLD}Total packages to process: ${TOTAL_PACKAGES}${NC}"

#########################
# INSTALL PACKAGES:
#########################

#############################################################################
# GNOME-SHELL MISSING RECOMMENDS (skipped by --no-install-recommends)
# --------------------------------------------------------------------------
# These packages are normally auto-installed as Recommends of gnome-shell.
# Active lines = essential for most desktop setups.
# Commented lines = only needed for specific hardware or use cases.
# Uncomment any line that matches your setup.
#############################################################################

show_title "Installing gnome-shell Recommended Libraries"

# --- ESSENTIAL FOR MOST DESKTOP SETUPS (active by default) ---

# evolution-data-server: Backend engine for GNOME's calendar, contacts, and
# online accounts (Google, Nextcloud, etc.). Powers the calendar popup in the
# top bar clock, event reminders in notifications, and contact lookups.
# WITHOUT IT: No calendar events in the top bar, no online account sync,
# gnome-calendar and gnome-contacts won't function properly.
install_package_no_recommendations "evolution-data-server" "Data Server: Backend for calendar, contacts, and online accounts integration"

# gnome-menus: Provides the application menu layout and .desktop file categories
# (Accessories, System Tools, etc.). Used by the Activities overview and app grid
# to organize and display installed applications.
# WITHOUT IT: Apps may not appear in categorized views, and some third-party
# app launchers or menu extensions may break.
install_package_no_recommendations "gnome-menus" "App Menus: Provides category structure for application listings in the shell"

# power-profiles-daemon: D-Bus service that exposes power profile switching
# (Power Saver / Balanced / Performance) to the GNOME Settings > Power panel
# and the quick settings menu in the top bar.
# WITHOUT IT: No power profile toggle in Settings or quick settings.
# System runs on whatever the kernel default is. Mostly affects laptops.
install_package "power-profiles-daemon" "Power Profiles: Enables Power Saver/Balanced/Performance switching in Settings"

# unzip: Standard ZIP archive extraction tool. Used by Nautilus for opening ZIP
# files, by gnome-shell for extracting extension archives, and by various GNOME
# components that handle compressed content.
# WITHOUT IT: Cannot extract ZIP files in Nautilus, and some shell extension
# operations may fail silently.
install_package_no_recommendations "unzip" "Unzip: ZIP archive extraction used by Nautilus and shell extensions"

# --- ALREADY INSTALLED ELSEWHERE IN YOUR SCRIPT (no action needed) ---

# gdm3: GNOME Display Manager (the login screen). This is already installed
# in the Debian-specific section of install-gnome.sh, so no need to add it here.
# install_package "gdm3" "Display Manager: Already installed in distro-specific section"

# --- OPTIONAL: UNCOMMENT BASED ON YOUR HARDWARE / USE CASE ---

# bolt: Thunderbolt 3/4 device manager daemon. Handles security authorization
# of Thunderbolt peripherals (docks, eGPUs, external drives) when plugged in.
# UNCOMMENT IF: You use Thunderbolt docks, eGPUs, or Thunderbolt storage devices.
# SKIP IF: You only use USB, HDMI, and DisplayPort peripherals.
install_package_no_recommendations "bolt" "Thunderbolt Manager: Authorizes Thunderbolt 3/4 docks, eGPUs, and peripherals"

# gnome-browser-connector: Bridge between your web browser (Firefox/Chrome) and
# the extensions.gnome.org website, allowing one-click install of shell extensions
# from the browser.
# UNCOMMENT IF: You prefer installing extensions via the browser instead of the
# Extension Manager app.
# SKIP IF: You already have gnome-shell-extension-manager (installed in your script)
# which is the standalone alternative that doesn't need a browser.
# NOTE: On Debian this package is called "chrome-gnome-shell" (already in your script).
#install_package "gnome-browser-connector" "Browser Connector: One-click shell extension installs from extensions.gnome.org"

# gnome-remote-desktop: Built-in RDP and VNC remote desktop server for GNOME.
# Integrates with Settings > Sharing > Remote Desktop / Remote Login.
# Allows other computers to view and control your desktop remotely.
# UNCOMMENT IF: You need to remotely access this machine from another computer.
# SKIP IF: You always use this machine locally, or use a third-party remote
# desktop solution like AnyDesk, RustDesk, or SSH with X forwarding.
#install_package "gnome-remote-desktop" "Remote Desktop: Built-in RDP/VNC server for remote access via Settings > Sharing"

# gnome-user-docs: The official GNOME help documentation, viewed through the
# yelp help browser. Provides the content behind Help menus in GNOME apps.
# WARNING: This package pulls in 'yelp' as a hard dependency!
# UNCOMMENT IF: You want the built-in help system and don't mind yelp being installed.
# SKIP IF: You want to keep yelp off the system (which is likely why you're
# using --no-install-recommends in the first place).
#install_package "gnome-user-docs" "GNOME Help Docs: Built-in help pages (WARNING: pulls in yelp!)"

# ibus: Intelligent Input Bus framework for typing in CJK (Chinese, Japanese,
# Korean) and other complex-script languages. Provides the input method switcher
# in the top bar and the keyboard layout engine for non-Latin input.
# UNCOMMENT IF: You type in Chinese, Japanese, Korean, Vietnamese, or any
# language that requires an input method editor (IME).
# SKIP IF: You only type in English, Arabic, or other languages that work
# directly with standard keyboard layouts (no IME needed).
#install_package "ibus" "Input Bus: Input method framework for CJK and complex-script languages"

# iio-sensor-proxy: Daemon that reads hardware sensors via the Industrial I/O
# subsystem — accelerometers (for auto screen rotation) and ambient light
# sensors (for automatic brightness adjustment).
# UNCOMMENT IF: You have a convertible laptop, tablet, or a device with an
# ambient light sensor for auto-brightness.
# SKIP IF: You use a traditional desktop or non-convertible laptop.
#install_package "iio-sensor-proxy" "Sensor Proxy: Enables auto-rotate and auto-brightness on tablets/convertibles"

# switcheroo-control: D-Bus service that detects dual-GPU / hybrid graphics
# setups (e.g. Intel integrated + NVIDIA discrete). Enables the "Launch using
# Discrete Graphics Card" right-click option on application icons in GNOME.
# UNCOMMENT IF: Your machine has dual GPUs (very common on gaming/workstation laptops).
# SKIP IF: You have a single GPU (most desktops, or laptops with only integrated graphics).
install_package_no_recommendations "switcheroo-control" "GPU Switcher: Enables 'Launch using Discrete GPU' option for hybrid graphics"

#############################################################################
# GNOME-SESSION SUGGESTS (not installed even with normal apt-get install)
# --------------------------------------------------------------------------
# gnome-session has NO Recommends, so --no-install-recommends has zero effect.
# These are Suggests only — listed here for reference if you want them.
#############################################################################

# desktop-base: Debian-specific wallpapers, themes, and boot splash branding.
# Provides the default Debian desktop background and Plymouth boot theme.
# UNCOMMENT IF: You want the official Debian Trixie wallpaper and branding.
# SKIP IF: You plan to set your own wallpaper and custom theme anyway.
#install_package "desktop-base" "Debian Branding: Default Debian wallpapers, themes, and boot splash artwork"

# gnome-keyring: Daemon that stores passwords, encryption keys, SSH keys, and
# secrets securely. Integrates with GNOME apps, Chrome/Firefox password prompts,
# and SSH agent for passwordless SSH connections.
# NOTE: This is highly recommended even though it's only a Suggest. Many apps
# and services (Git credential storage, Wi-Fi passwords, browser keyrings)
# rely on it. Consider keeping this active.
install_package_no_recommendations "gnome-keyring" "Keyring: Secure storage for passwords, SSH keys, and secrets used by many apps"

# Exit the script
exit 0
