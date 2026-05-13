#!/usr/bin/env bash

# ==============================================================================
# Script Name:  migrate-libvirt.sh
# Description:  Automates migration from monolithic libvirtd to modular daemons
# Target OS:    Arch Linux
# Created By:   AhmdHosni (ahmdhosny@gmail.com)
# ==============================================================================

# Ensure the script is run with root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Please run this script using sudo."
    exit 1
fi

echo "======================================================================"
echo "⚡ Starting Libvirt Modular Migration"
echo "======================================================================"

# ------------------------------------------------------------------------------
# STEP 1: Tear Down Legacy Monolithic Daemon
# ------------------------------------------------------------------------------
echo "🧹 Stopping and disabling legacy monolithic libvirtd..."
systemctl disable --now libvirtd.service libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket

# ------------------------------------------------------------------------------
# STEP 2: Deploy and Activate Modular Components
# ------------------------------------------------------------------------------
echo "⚙️  Enabling and starting modern modular sockets..."
# Core hypervisor management, virtual networking, and storage management
systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket

echo "📝 Enabling logging and file-locking helper components..."
# Essential system helpers to keep VM logs and disk locking healthy
systemctl enable --now virtlogd.socket virtlockd.socket

# ------------------------------------------------------------------------------
# STEP 3: Configure Default System Environment URI
# ------------------------------------------------------------------------------
echo "🌐 Configuring default system URI environment variables..."

# Detect the real user who invoked sudo to target their correct home directory
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Locate the active Zsh configuration file
ZSHRC_PATH="$REAL_HOME/.config/zsh/.zshrc"

if [ -f "$ZSHRC_PATH" ]; then
    # Verify if the variable configuration already exists before writing
    if ! grep -q "LIBVIRT_DEFAULT_URI" "$ZSHRC_PATH"; then
        echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >>"$ZSHRC_PATH"
        echo "✅ System URI configured in: $ZSHRC_PATH"
    else
        echo "ℹ️  System URI environment variable already found in $ZSHRC_PATH."
    fi
else
    echo "⚠️  Warning: Could not find Zsh configuration at $ZSHRC_PATH"
fi

# ------------------------------------------------------------------------------
# STEP 4: Post-Migration Integration Check
# ------------------------------------------------------------------------------
echo "======================================================================"
echo "🎯 Migration Complete! System Status Checks:"
echo "======================================================================"

# Quick visual status verification of the primary QEMU socket broker
systemctl is-active --quiet virtqemud.socket && echo "● QEMU Socket:  ACTIVE" || echo "● QEMU Socket:  FAILED"
systemctl is-active --quiet virtnetworkd.socket && echo "● Net Socket:   ACTIVE" || echo "● Net Socket:   FAILED"
systemctl is-active --quiet virtstoraged.socket && echo "● Store Socket: ACTIVE" || echo "● Store Socket: FAILED"

echo "------------------------------------------------------------------"
echo "💡 Next Steps:"
echo "1. Run 'source $ZSHRC_PATH' or restart your terminal window."
echo "2. Create your brand-new virtual machine."
echo "======================================================================"
