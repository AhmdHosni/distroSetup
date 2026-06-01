#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          android-studio-libraries.sh
# Created:       Monday, 01 June 2026 - 11:26 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:
#--------------------------------------------------------------------------------

#!/usr/bin/env bash
set -e

echo "========================================================"
echo " Setting up Arch Linux Dependencies for Android Studio"
echo "========================================================"

# 1. Ensure multilib is enabled
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "[*] Enabling [multilib] repository..."
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
fi

# 2. Install official packages (Removed lib32-libstdc++5 from here)
echo "[*] Syncing repositories and installing core dependencies..."
sudo pacman -Syu --needed --noconfirm \
    android-udev \
    libglvnd \
    freetype2 \
    alsa-lib \
    libxtst \
    lib32-glibc \
    lib32-gcc-libs

# 3. Install AUR dependencies (Both ncurses5 and lib32-libstdc++5)
if command -v yay &>/dev/null; then
    echo "[*] Installing legacy AUR dependencies via yay..."
    yay -S --needed --noconfirm ncurses5-compat-libs lib32-libstdc++5
elif command -v paru &>/dev/null; then
    echo "[*] Installing legacy AUR dependencies via paru..."
    paru -S --needed --noconfirm ncurses5-compat-libs lib32-libstdc++5
else
    echo "[!] Warning: No AUR helper found. Please install 'lib32-libstdc++5' and 'ncurses5-compat-libs' manually from the AUR."
fi

# 4. Configure groups
echo "[*] Configuring user permissions..."
CURRENT_USER=$(whoami)
sudo usermod -aG kvm "$CURRENT_USER"
sudo usermod -aG adbusers "$CURRENT_USER"

echo "========================================================"
echo " [✓] Dependency Setup Complete! Please log out and back in."
echo "========================================================"
