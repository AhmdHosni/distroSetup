#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          install_nautilus_image_preview_libraries.sh
# Created:       Sunday, 15 February 2026 - 08:33 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:   This scripts installs important libraries to preview image thumbnails in nautilus
#--------------------------------------------------------------------------------

#####################
# PREPARE DIRCTORIES:
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

if command -v apt-get &>/dev/null; then

    # This is essential for rendering Scalable Vector Graphics (SVG) files into thumbnails
    install_package "librsvg2-common" "This is essential for rendering Scalable Vector Graphics (SVG) files into thumbnails"
    # The GDK Pixbuf library, which provides the base thumbnailing capability for standard image formats.
    install_package "libgdk-pixbuf2.0-bin" "The GDK Pixbuf library, which provides the base thumbnailing capability for standard image formats."
    # To see thumbnails for camera raw files, install exiv2
    install_package "exiv2" " To see thumbnails for camera raw file"
    # To see thumbnails for raw images
    install_package "nautilus-raw-thumbnails" "To see thumbnails for raw images"
    # To generate previews for video files (Video Thumbnails)
    install_package "ffmpegthumbnailer" "To generate previews for video files (Video Thumbnails)"
    # Sushi: Cool nautilus plugin. Recommended for a quick previewer (press Spacebar in Nautilus
    install_package "gnome-sushi" "Cool nautilus plugin. Recommended for a quick previewer (press Spacebar in Nautilus"

    # Finally clean the old thumbnail cache to create new ones
    rm -rf $HOME/.cache/thumbnails/*
    # force quit nautilus
    nautilus -q

fi
