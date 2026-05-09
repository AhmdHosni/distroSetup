#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          install-kvm-and-libvirt.sh
# Created:       Saturday, 09 May 2026 - 10:49 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:
#--------------------------------------------------------------------------------

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"
start_tmux
cache_sudo

show_title "Install KVM and Virtualization Tools"

if [ "$DISTRO" = "debian" ]; then

    # --- KVM & Virtualization (Debian 13) ---
    ##show_title "Install KVM and Virtualization Tools"
    install_package "qemu-system-x86" "QEMU base for x86 virtualization"
    install_package "libvirt-daemon-system" "Libvirt virtualization daemon"
    install_package "libvirt-clients" "Libvirt client-side tools"
    install_package "dnsmasq-base" "Small forwarder for virtual networks"
    install_package "virt-manager" "Graphical VM manager"
    install_package "vde2" "Virtual Distributed Ethernet"
    install_package "netcat-openbsd" "TCP/IP swiss army knife (OpenBSD version)"
    install_package "dmidecode" "DMI table decoder"
    install_package "swtpm" "Software TPM emulator for Windows 11"
    install_package "ovmf" "UEFI firmware for virtual machines"
    install_package "qemu-system-modules-spice" "Spice support for QEMU"
    install_package "gir1.2-spiceclientgtk-3.0" "GObject introspection for Spice"

elif [ "$DISTRO" = "arch" ]; then
    # --- KVM & Virtualization ---
    install_package "qemu-base" "QEMU base package"
    install_package "libvirt" "Libvirt virtualization library"
    install_package "dnsmasq" "DNS/DHCP server for virtual networks"
    install_package "virt-manager" "Graphical VM manager"
    # install_package "bridge-utils" "Network bridge utilities"     # dpericated use iprout2 or get bridge-utils from aur.
    install_package "vde2"
    install_package "openbsd-netcat"
    install_package "dmidecode"
    install_package "swtpm" "Needed library if you want to install windows11"
    install_package "libtpms" "Needed library if you want to install windows11"
    install_package "edk2-ovmf" "Needed library if you want to install windows11"
    install_package "qemu-hw-display-qxl" "Needed for qxl option of graphic adapter"
    install_package "spice" "Needed for spice display option"
    install_package "qemu-chardev-spice " "Needed for spice display option"
    install_package "qemu-ui-spice-core" "qemu-ui-spice-core: Provides the essential engine for the Spice display"
    install_package "qemu-ui-spice-app" " qemu-ui-spice-app: Allows virt-manager to launch the display correctly."
    install_package "qemu-audio-spice" " qemu-audio-spice: Fixes potential audio errors related to the Spice"

fi

### Missing:

# Detect Distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Unsupported distribution."
    exit 1
fi

echo "Detected: $DISTRO"

# 1. Update GRUB with IOMMU Parameter
# This targets Intel CPUs as per your logs (VMX/DMAR)
PARAM="intel_iommu=on"
GRUB_FILE="/etc/default/grub"

if grep -q "$PARAM" "$GRUB_FILE"; then
    echo "✓ IOMMU parameter already exists in $GRUB_FILE"
else
    echo "Adding $PARAM to $GRUB_FILE..."
    sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$PARAM /" "$GRUB_FILE"
fi

# 2. Update GRUB Bootloader Configuration
echo "Updating GRUB configuration..."
case $DISTRO in
arch)
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    ;;
debian | ubuntu)
    sudo update-grub
    ;;
fedora)
    # Modern Fedora (v34+) uses a symlink to /boot/grub2/grub.cfg for both BIOS and UEFI
    sudo grub2-mkconfig -o /etc/grub2.cfg
    ;;
*)
    echo "Distribution not recognized for GRUB update. Please run your distro's grub-update command manually."
    ;;
esac

# --- User permissions ---
show_title "Grant User Permissions to libvirt and kvm"
add_user_to_groups libvirt kvm

# --- Enable services ---
show_title "Enable libvirt Services"
enable_service "libvirtd"

# Enable and start the Default Network
show_title "Enable and start the Default Network"
sudo virsh net-start default
sudo virsh net-autostart default

# valicate virt-hosts
show_title "valicate virt-hosts"
virt-host-validate qemu

echo "===================================================="
echo "FIXES APPLIED SUCCESSFULLY"
echo "===================================================="
echo "1. IOMMU: Added to kernel command line."
echo "2. Groups: Ensure you LOG OUT and LOG IN for permissions."
echo "3. Action Required: REBOOT your system now."
echo "===================================================="

#####################
# Done
#####################

show_title "Complete" "All the needed packages for virtualization is now installed, Virtualization is now ready."
echo ""

################
# Exit script:
################
exit 0
