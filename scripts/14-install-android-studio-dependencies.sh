#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          install_android_studio_requirements.sh
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Description:   Installs Android Studio requirements for Debian or Arch Linux.
#                 Uses the global shared library at /etc/ahmdhosni/lib_functions.sh
#--------------------------------------------------------------------------------

#####################
# Source Global Library
#####################

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"
start_tmux
cache_sudo

#####################
# Count Total Packages
#####################

if [ "$DISTRO" = "debian" ]; then
    TOTAL_PACKAGES=11 # 5 (32-bit) + 1 (JDK) + 5 (KVM)
else
    TOTAL_PACKAGES=15 # 1 (udev) + 9 (32-bit) + 1 (JDK) + 5 (KVM/qemu)
fi

######################
# Defining Directores:
######################
ANDROID_STUDIO_SHORTCUT_SOURCE_DIR="$THIS_DIR/configs/android"
ANDROID_STUDIO_SHORTCUT_DESTINATION_DIR="$HOME/.local/share/applications"

###############################
# Copy Android Studio Shortcut:
###############################

show_title "Copy android studio desktop shortcut"
copy_file "$ANDROID_STUDIO_SHORTCUT_SOURCE_DIR/android-studio.desktop" "$ANDROID_STUDIO_SHORTCUT_DESTINATION_DIR"

################################################
# create and set custom icon of .android folder:
###############################################
# set_folder_icon "TargetFolder" "PathToCustomIcon.png" "Description"
FOLDER_ICON_SOURCE_FILE="$THIS_DIR/configs/icons/pngs/android.png"
TARGET_FOLDER="$HOME/.android" && mkdir -p $TARGET_FOLDER/.icon
copy_file "$FOLDER_ICON_SOURCE_FILE" "$TARGET_FOLDER/.icon"
set_folder_icon "$TARGET_FOLDER" "$TARGET_FOLDER/.icon/android.png" "setting custom icon to .android folder"

#####################
# Main Install
#####################

show_title "Android Studio Requirements — ${DISTRO}"

if [ "$DISTRO" = "debian" ]; then

    TOTAL_PACKAGES=$(grep -c "^install_package" "$0")
    echo ""
    echo -e "${CYAN}${BOLD}Total packages to process: ${TOTAL_PACKAGES}${NC}"

    # --- Enable 32-bit architecture ---
    show_title "Enable 32-bit Architecture"
    echo -e "${YELLOW}${BOLD}Adding i386 architecture...${NC}"
    if sudo dpkg --add-architecture i386 && sudo apt-get update -y &>/dev/null; then
        echo -e "${GREEN}✓ i386 architecture enabled and repo updated${NC}"
    else
        echo -e "${RED}✗ Failed to enable i386 architecture${NC}"
    fi

    # --- 32-bit libraries ---
    show_title "Install 32-bit Libraries"
    install_package "libc6:i386" "Core 32-bit C library"
    install_package "libncurses6:i386" "32-bit ncurses terminal library"
    install_package "libstdc++6:i386" "32-bit C++ standard library"
    install_package "lib32z1" "32-bit zlib compression library"
    install_package "libbz2-1.0:i386" "32-bit bzip2 compression library"

    # --- JDK ---
    # show_title "Install open JDK"
    # install_package "openjdk-25-jdk" "Java Development Kit 25"

    # --- Flutter dependencies  ---
    show_title "Install Fluttr dependencies"
    install_package "curl"
    install_package "git"
    install_package "zip"
    install_package "unzip"
    install_package "xz-utils"
    install_package "libglu1-mesa"

    # --- KVM & Virtualization ---
    show_title "Install KVM and Virtualization Tools"
    install_package "qemu-kvm" "QEMU/KVM hypervisor"
    install_package "libvirt-daemon-system" "Libvirt virtualization daemon"
    install_package "libvirt-clients" "Libvirt client tools"
    install_package "bridge-utils" "Network bridge utilities"
    install_package "virt-manager" "Graphical VM manager for GNOME"

    # --- User permissions ---
    show_title "Grant User Permissions to libvirt and kvm"
    add_user_to_groups libvirt kvm

    # --- Enable services ---
    show_title "Enable libvirt Services"
    enable_service "libvirtd"

elif [ "$DISTRO" = "arch" ]; then

    TOTAL_PACKAGES=$(grep -c "^install_package" "$0")
    echo ""
    echo -e "${CYAN}${BOLD}Total packages to process: ${TOTAL_PACKAGES}${NC}"

    # --- UDEV rules ---
    show_title "Install Android UDEV Rules"
    install_package "android-udev" "UDEV rules for Android USB devices"

    # --- 32-bit libraries ---
    show_title "Install 32-bit Libraries"
    install_package "lib32-glibc" "32-bit GNU C library"
    install_package "lib32-gcc-libs" "32-bit GCC runtime libraries"
    install_package "lib32-zlib" "32-bit zlib compression library"
    install_package "lib32-ncurses" "32-bit ncurses terminal library"
    install_package "lib32-alsa-lib" "32-bit ALSA sound library"
    install_package "freetype2" "Font rendering library"
    install_package "libxrender" "X11 rendering extension"
    install_package "libxtst" "X11 test extension"
    install_package "libglvnd" "OpenGL vendor-neutral dispatch library"

    # --- JDK ---
    show_title "Install open JDK"
    install_package "jdk-openjdk" "Java Development Kit (OpenJDK)"

    # --- KVM & Virtualization ---
    show_title "Install KVM and Virtualization Tools"
    install_package "qemu-base" "QEMU base package"
    install_package "libvirt" "Libvirt virtualization library"
    install_package "dnsmasq" "DNS/DHCP server for virtual networks"
    install_package "virt-manager" "Graphical VM manager"
    install_package "bridge-utils" "Network bridge utilities"

    # --- User permissions ---
    show_title "Grant User Permissions"
    add_user_to_groups kvm libvirt

    # --- Enable services ---
    show_title "Enable Libvirt Services"
    enable_service "libvirtd"

fi

#####################
# Done
#####################

show_title "Complete" "All Android Studio requirements are now installed."
echo ""

################
# Exit script:
################
exit 0
