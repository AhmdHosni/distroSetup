#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          09-open-terminal-with-kitty.sh (REFINED)
# Created:       Friday, 23 January 2026 - 04:28 PM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Description:   Installs nautilus-open-any-terminal plugin to open Kitty
#                in any directory from Nautilus right-click menu
#--------------------------------------------------------------------------------

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"
start_tmux
cache_sudo

# Git clone destination
GIT_CLONE_DIR="$HOME/Downloads/git"
REPO_URL="https://github.com/Stunkymonkey/nautilus-open-any-terminal.git"
REPO_DEST="$GIT_CLONE_DIR/nautilus-open-any-terminal"

# Create git clone directory
mkdir -p "$GIT_CLONE_DIR"

show_title "Installing Nautilus Open Any Terminal" "Open Kitty from Nautilus right-click menu"

###############
# DEPENDENCIES
###############

# Calculate total packages
TOTAL_PACKAGES=0
if [ "$DISTRO" = "debian" ]; then
    TOTAL_PACKAGES=4
else
    TOTAL_PACKAGES=4
fi

echo ""
echo -e "${CYAN}${BOLD}Total packages to install: ${TOTAL_PACKAGES}${NC}"
echo ""

# Common packages
install_package "make" "Build tool for compiling from source"
install_package "gettext" "Internationalization utilities"

# Distro-specific packages
if [ "$DISTRO" = "debian" ]; then
    install_package "gir1.2-gtk-4.0" "GTK 4 introspection bindings for Python"
    install_package "python3-nautilus" "Python bindings for Nautilus extensions"
else
    install_package "gtk4" "GTK 4 toolkit"
    install_package "python-nautilus" "Python bindings for Nautilus extensions"
fi

#####################
# CLONE REPOSITORY
#####################

show_title "Downloading Plugin"

git_clone "$REPO_URL" "$REPO_DEST" "Nautilus Open Any Terminal plugin source code"

#####################
# BUILD AND INSTALL
#####################

show_title "Building and Installing"

# Build the plugin
build_from_source "$REPO_DEST" \
    "make" \
    "sudo make install schema" \
    "Nautilus Open Any Terminal plugin (system-wide)"

#####################
# COMPILE SCHEMAS
#####################

show_title "Compiling GLib Schemas"

# Compile system-wide schemas
compile_glib_schemas "/usr/share/glib-2.0/schemas" \
    "System-wide GLib schemas for plugin configuration" \
    "sudo"

#####################
# RESTART NAUTILUS
#####################

echo ""
echo -e "${CYAN}${BOLD}Restarting Nautilus to load the new extension...${NC}"

if nautilus -q 2>/dev/null; then
    echo -e "${GREEN}✓ Nautilus restarted${NC}"
    sleep 1
else
    echo -e "${YELLOW}⚠ Nautilus was not running${NC}"
fi

#####################
# CONFIGURE PLUGIN
#####################

show_title "Configuring Plugin"

echo -e "${CYAN}Setting up Kitty as the default terminal...${NC}"
echo ""

# Set kitty as the terminal
set_gsetting "com.github.stunkymonkey.nautilus-open-any-terminal" \
    "terminal" \
    "kitty" \
    "Set Kitty as the default terminal"

# Set keyboard shortcut
set_gsetting "com.github.stunkymonkey.nautilus-open-any-terminal" \
    "keybindings" \
    "'<Ctrl><Alt>t'" \
    "Keyboard shortcut: Ctrl+Alt+T"

# Open terminal in new tab (not new window)
set_gsetting "com.github.stunkymonkey.nautilus-open-any-terminal" \
    "new-tab" \
    "true" \
    "Open terminal in new tab instead of new window"

#####################
# INSTALLATION COMPLETE
#####################

echo ""
show_title "Installation Complete!" "Kitty terminal integration ready"

echo -e "${GREEN}${BOLD}Summary:${NC}"
echo -e "${GREEN}  ✓ Dependencies installed${NC}"
echo -e "${GREEN}  ✓ Plugin source downloaded${NC}"
echo -e "${GREEN}  ✓ Plugin built and installed${NC}"
echo -e "${GREEN}  ✓ GLib schemas compiled${NC}"
echo -e "${GREEN}  ✓ Plugin configured for Kitty${NC}"
echo ""
echo -e "${CYAN}${BOLD}How to use:${NC}"
echo -e "${CYAN}  1. Open Nautilus file manager${NC}"
echo -e "${CYAN}  2. Right-click in any folder${NC}"
echo -e "${CYAN}  3. Select 'Open in Kitty' from the menu${NC}"
echo -e "${CYAN}  4. Or press Ctrl+Alt+T${NC}"
echo ""

exit 0
