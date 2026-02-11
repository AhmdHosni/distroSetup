#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          mount-storage-device.sh
# Created:       Saturday, 31 January 2026 - 07:19 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:   This script mount Storage device to the system and add it to /etc/fstab
#--------------------------------------------------------------------------------

# This script runs as root, otherwize we will have a conflict and will not execute (it does with no result)

# Don't add lib-functions here, it confilicts with the below order
# Dont't add cache_sudo as this is root (cached sudo will conflict)
# and no start_tmux as tmux is not needed for this script

###################
# Color definitions
###################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

set -e # Exit on any error (but we'll handle specific ones)

UUID="DEE2AF03E2AEDF51"                # Storage UUID
MOUNT_POINT="/media/ahmdhosni/Storage" # Storage Mount Point
DEVICE="/dev/disk/by-uuid/$UUID"

echo ""
echo -e "${CYAN}${BOLD}==========================================${NC}"
echo -e "${CYAN}${BOLD}Mounting Storage Device                   ${NC}"
echo -e "${CYAN}${BOLD}UUID: $UUID                               ${NC}"
echo -e "${CYAN}${BOLD}Mount Point: $MOUNT_POINT                 ${NC}"
echo -e "${CYAN}${BOLD}==========================================${NC}"
echo ""

# STEP 1: Create mount point if it doesn't exist
echo "[1/4] Checking mount point..."
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Creating mount point: $MOUNT_POINT"
    if sudo mkdir -p "$MOUNT_POINT"; then
        echo -e "${GREEN}${BOLD}✓ Mount point created successfully${NC}"
    else
        echo -e "${GREEN}${BOLD}✗ ERROR: Failed to create mount point${NC}"
        exit 1
    fi
else
    echo -e "${BLUE}✓ Mount point already exists${NC}"
fi

# STEP 2: Check if device exists
echo ""
echo -e "[2/4] Checking if device exists..."
if [ ! -e "$DEVICE" ]; then
    echo -e "${RED}✗ ERROR: Device $DEVICE not found${NC}"
    echo -e "${RED}Please check if the disk is connected and UUID is correct${NC}"
    exit 1
else
    echo -e "${CYAN}✓ Device found: $DEVICE ${NC}"
fi

# STEP 3: Check if already mounted
echo ""
echo "[3/4] Checking mount status..."
if findmnt -M "$MOUNT_POINT" >/dev/null 2>&1; then
    echo -e "${BLUE}✓ Device is already mounted at $MOUNT_POINT ${NC}"
else
    # Mount by UUID
    echo "Mounting $UUID to $MOUNT_POINT..."
    if sudo mount "$DEVICE" "$MOUNT_POINT"; then
        echo -e "${GREEN}${BOLD}✓ Mount successful ${NC}"
    else
        echo -e "${RED}✗ ERROR: Mount failed${NC}"
        echo -e "${RED}Try running: sudo mount -t ntfs-3g $DEVICE $MOUNT_POINT ${NC}"
        exit 1
    fi
fi

# STEP 4: Add to /etc/fstab (only if not already there)
echo ""
echo "[4/4] Updating /etc/fstab..."

# Check if entry already exists in fstab
if grep -q "UUID=$UUID" /etc/fstab; then
    echo -e "${BLUE}✓ Entry already exists in /etc/fstab ${NC}"
else
    echo "Adding entry to /etc/fstab..."

    # Backup fstab first
    if sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S); then
        echo -e "${GREEN}✓ Backup created: /etc/fstab.backup.$(date +%Y%m%d_%H%M%S) ${NC}"
    else
        echo -e "${YELLOW}✗ WARNING: Failed to backup fstab, but continuing... ${NC}"
    fi

    # Add entry to fstab
    {
        echo ""
        echo "# Storage device - Auto-mounted"
        echo "UUID=$UUID    $MOUNT_POINT    ntfs    defaults,uid=1000,gid=1000,dmask=000,fmask=000    0    3"
    } | sudo tee -a /etc/fstab >/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Entry added to /etc/fstab successfully ${NC}"
    else
        echo -e "${RED}✗ ERROR: Failed to update /etc/fstab{$NC}"
        exit 1
    fi
fi

# STEP 5: Verify the mount
echo ""
echo "Verifying mount..."
if mountpoint -q "$MOUNT_POINT"; then
    echo -e "${GREEN}✓ Mount point is valid ${NC}"

    # Test if we can list contents
    if sudo ls "$MOUNT_POINT" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Can access mounted directory ${NC}"
    else
        echo -e "${YELLOW}✗ WARNING: Mount point exists but cannot list contents ${NC}"
    fi
else
    echo -e "${RED}✗ ERROR: Mount point verification failed ${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}${BOLD}==========================================${NC}"
echo -e "${GREEN}${BOLD}SUCCESS: Storage device mounted successfully!${NC}"
echo -e "${GREEN}${BOLD}==========================================${NC}"
echo -e "${CYAN}${BOLD}Mount point: $MOUNT_POINT ${NC}"
echo -e "${GREEN}${BOLD}Device will auto-mount on boot via /etc/fstab ${NC}"
echo ""

# No reboot needed for this script
exit 0
