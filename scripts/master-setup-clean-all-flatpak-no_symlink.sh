#!/bin/bash
# =============================================================================
# MASTER SETUP SCRIPT — Dell Precision 7530
# =============================================================================
# Covers everything for a fresh Arch Linux or Debian 13 install:
#
#   ARCH (linux-zen + Hyprland or GNOME 50):
#     ✓ NVIDIA Pascal driver (nvidia-580xx-dkms) via AUR
#     ✓ UKI-aware nvidia-toggle (Intel/Hybrid mode switching)
#     ✓ Pacman hook for NVIDIA DKMS rebuild on kernel updates
#     ✓ Hyprland config (NVIDIA env vars + HDMI mirror + workspace rules)
#     ✓ GNOME 50 config (environment.d + GDM)
#     ✓ Steam + Proton + lib32-nvidia-580xx-utils
#     ✓ Waybar modules (GPU, fan, temperature)
#     ✓ Game saves symlinked to storage drive
#
#   DEBIAN 13 (GNOME 48/50):
#     ✓ fstab btrfs safety fix (pass=0 for all btrfs entries)
#     ✓ NVIDIA driver (nvidia-driver + dkms)
#     ✓ Libvirt disabled (shutdown noise fix)
#     ✓ udev HDMI rule removed (home unmount fix)
#     ✓ HDMI mirror via GNOME autostart
#     ✓ Steam via Flatpak + game saves
#
#   BOTH:
#     ✓ nvidia-toggle (Intel-only / Hybrid switching)
#     ✓ Civ6 aspyr-media save symlink
#
# Usage:
#   chmod +x master-setup.sh
#   ./master-setup.sh
# =============================================================================

set -e

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() {
    echo -e "${RED}[✗]${NC} $1"
    exit 1
}
info() { echo -e "${CYAN}[i]${NC} $1"; }
skip() { echo -e "${MAGENTA}[-]${NC} $1 — skipping"; }
section() {
    echo -e "\n${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
}
banner() {
    echo -e "\n${MAGENTA}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║  $1${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════╝${NC}"
}

[ "$EUID" -eq 0 ] && error "Do not run as root. Run as your normal user."

# =============================================================================
# STEP 0 — Detect system and ask user what to install
# =============================================================================
banner "Dell Precision 7530 — Master Setup Script"

echo ""
info "Detecting system..."

# Detect distro
if grep -qi "arch" /etc/os-release 2>/dev/null; then
    DISTRO="arch"
elif grep -qi "debian" /etc/os-release 2>/dev/null; then
    DISTRO="debian"
elif grep -qi "fedora" /etc/os-release 2>/dev/null; then
    DISTRO="fedora"
    FEDORA_VER=$(grep "^VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
else
    error "Unsupported distro. This script supports Arch Linux, Debian 13, and Fedora only."
fi

# Detect DE
DESKTOP="none"
if command -v hyprctl &>/dev/null; then
    DESKTOP="hyprland"
elif command -v gnome-shell &>/dev/null; then
    GNOME_VER=$(gnome-shell --version 2>/dev/null | awk '{print $3}' | cut -d'.' -f1)
    DESKTOP="gnome"
fi

# Detect kernel
KERNEL=$(uname -r)

# Detect boot type
IS_UKI=false
[ -f "/etc/kernel/cmdline" ] && IS_UKI=true

# Detect AUR helper
AUR_HELPER=""
command -v paru &>/dev/null && AUR_HELPER="paru"
command -v yay &>/dev/null && AUR_HELPER="yay"

# Detect GPUs
HAS_INTEL=$(lspci | grep -i "VGA\|3D" | grep -ic "intel" || true)
HAS_NVIDIA=$(lspci | grep -i "VGA\|3D" | grep -ic "nvidia" || true)
IS_HYBRID=false
[ "$HAS_INTEL" -gt 0 ] && [ "$HAS_NVIDIA" -gt 0 ] && IS_HYBRID=true

# Detect storage drive
STORAGE_PATH="/media/$USER/Storage/Games"
# FLATPAK_STORAGE="/media/$USER/Storage/Apps/Flatpak"
FLATPAK_STORAGE="$HOME/.var"
mkdir -p $FLATPAK_STORAGE
HAS_STORAGE=false
HAS_FLATPAK_STORAGE=false
[ -d "$STORAGE_PATH" ] && HAS_STORAGE=true
[ -d "$(dirname "$FLATPAK_STORAGE")" ] && HAS_FLATPAK_STORAGE=true

echo ""
info "═══ System Detected ═══"
info "Distro:    $DISTRO"
info "Kernel:    $KERNEL"
info "Desktop:   $DESKTOP"
info "Boot:      $([ "$IS_UKI" = true ] && echo 'UKI (Unified Kernel Image)' || echo 'Standard GRUB')"
info "AUR:       ${AUR_HELPER:-none found}"
info "Intel GPU: $([ "$HAS_INTEL" -gt 0 ] && echo 'yes' || echo 'no')"
info "NVIDIA:    $([ "$HAS_NVIDIA" -gt 0 ] && echo 'yes' || echo 'no')"
info "Hybrid:    $([ "$IS_HYBRID" = true ] && echo 'yes' || echo 'no')"
info "Storage:   $([ "$HAS_STORAGE" = true ] && echo "$STORAGE_PATH" || echo 'not mounted')"
[ "$DISTRO" = "fedora" ] && info "Fedora:    $FEDORA_VER"
echo ""

# =============================================================================
# Auto-select modules based on detected system
# =============================================================================
section "Auto-detected Installation Plan"

# ── Smart defaults based on detection ────────────────────────────────────────

# NVIDIA driver — always if NVIDIA GPU present
do_nvidia=false
[ "$HAS_NVIDIA" -gt 0 ] && do_nvidia=true

# nvidia-toggle — always if hybrid GPU
do_toggle=false
[ "$IS_HYBRID" = true ] && do_toggle=true

# Pacman DKMS hook — Arch only
do_hook=false
[ "$DISTRO" = "arch" ] && do_hook=true

# Hyprland config — Arch + Hyprland only
do_hyprland=false
[ "$DISTRO" = "arch" ] && [ "$DESKTOP" = "hyprland" ] && do_hyprland=true

# GNOME config — if GNOME detected, or Arch minimal (offer GNOME setup)
do_gnome=false
[ "$DESKTOP" = "gnome" ] && do_gnome=true
[ "$DISTRO" = "arch" ] && [ "$DESKTOP" = "none" ] && do_gnome=false # fresh arch, no DE yet

# Steam — always
do_steam=true

# Waybar — Arch + Hyprland only
do_waybar=false
[ "$DISTRO" = "arch" ] && [ "$DESKTOP" = "hyprland" ] && do_waybar=true

# Build human-readable reason strings for display
reason_hyprland="Hyprland not detected on this system"
reason_waybar="Hyprland not detected on this system"
[ "$DISTRO" != "arch" ] && reason_hyprland="Arch Linux only"
[ "$DISTRO" != "arch" ] && reason_waybar="Arch Linux only"
[ "$DISTRO" = "arch" ] && [ "$DESKTOP" = "hyprland" ] && reason_hyprland="Arch + Hyprland detected"
[ "$DISTRO" = "arch" ] && [ "$DESKTOP" = "hyprland" ] && reason_waybar="Arch + Hyprland detected"

# Game saves — only if storage drive is mounted
do_saves=false
[ "$HAS_STORAGE" = true ] && do_saves=true

# ── Show detected plan ────────────────────────────────────────────────────────
echo ""
echo -e "  ${CYAN}Based on your system, the following will be installed:${NC}"
echo ""

show_item() {
    local enabled=$1 label=$2 reason=$3
    if [ "$enabled" = true ]; then
        echo -e "  ${GREEN}[✓]${NC} $label  ${CYAN}← $reason${NC}"
    else
        echo -e "  ${YELLOW}[-]${NC} $label  ${YELLOW}← $reason (skipped)${NC}"
    fi
}

show_item "$do_nvidia" "NVIDIA driver" "$DISTRO — NVIDIA GPU detected"
show_item "$do_toggle" "nvidia-toggle" "hybrid Intel+NVIDIA detected"
show_item "$do_hook" "Pacman DKMS hook" "Arch only"
show_item "$do_hyprland" "Hyprland config" "$reason_hyprland"
show_item "$do_gnome" "GNOME config" "GNOME detected"
show_item "$do_steam" "Steam" "$DISTRO install method"
show_item "$do_waybar" "Waybar modules (GPU/fan/temp)" "$reason_waybar"
show_item "$do_saves" "Game saves symlinks" "$([ "$HAS_STORAGE" = true ] && echo 'storage drive found' || echo 'storage drive not mounted')"

echo ""
echo -e "  ${CYAN}System profile:  ${YELLOW}$DISTRO${NC} + ${YELLOW}${DESKTOP:-minimal}${NC} + ${YELLOW}$([ "$IS_UKI" = true ] && echo 'UKI boot' || echo 'GRUB boot')${NC}"
echo ""

# ── Offer Hyprland/Waybar even if not currently detected ─────────────────────
# if [ "$DISTRO" = "arch" ] && [ "$DESKTOP" != "hyprland" ]; then
#     echo -e "  ${CYAN}Note:${NC} Hyprland is not your current desktop but you can still"
#     echo "  install Hyprland config files and Waybar modules for future use."
#     echo ""
#     read -rp "  Install Hyprland config + Waybar modules anyway? [y/N] " hl_extra
#     if [[ "$hl_extra" =~ ^[Yy]$ ]]; then
#         do_hyprland=true
#         do_waybar=true
#         log "Hyprland config + Waybar modules added to install plan."
#     fi
#     echo ""
# fi

# ── Allow manual override ─────────────────────────────────────────────────────
echo -e "  ${CYAN}Options:${NC}"
echo "  [Y] Accept auto-detected plan and proceed"
echo "  [C] Customise — choose modules manually"
echo "  [N] Cancel"
echo ""
read -rp "Choice [Y/c/n]: " plan_choice
plan_choice=${plan_choice:-Y}

if [[ "$plan_choice" =~ ^[Nn]$ ]]; then
    echo "Cancelled."
    exit 0
elif [[ "$plan_choice" =~ ^[Cc]$ ]]; then
    # Manual selection
    echo ""
    echo "  Enter modules to install (space-separated numbers):"
    echo ""
    echo "  [1] NVIDIA driver + hybrid GPU setup"
    echo "  [2] nvidia-toggle (Intel/Hybrid switching)"
    echo "  [3] Pacman hook (NVIDIA DKMS auto-rebuild) [Arch only]"
    echo "  [4] Hyprland config (env vars + HDMI + workspaces) [Arch only]"
    echo "  [5] GNOME config (environment.d + GDM + HDMI autostart)"
    echo "  [6] Steam"
    echo "  [7] Waybar modules (GPU/fan/temperature) [Arch only]"
    echo "  [8] Game saves → storage drive"
    echo "  [9] ALL"
    echo ""
    read -rp "Choice(s): " CHOICES

    do_nvidia=false
    do_toggle=false
    do_hook=false
    do_hyprland=false
    do_gnome=false
    do_steam=false
    do_waybar=false
    do_saves=false

    if echo "$CHOICES" | grep -q "9"; then
        do_nvidia=true
        do_toggle=true
        do_hook=true
        do_hyprland=true
        do_gnome=true
        do_steam=true
        do_waybar=true
        do_saves=true
    else
        echo "$CHOICES" | grep -q "1" && do_nvidia=true
        echo "$CHOICES" | grep -q "2" && do_toggle=true
        echo "$CHOICES" | grep -q "3" && do_hook=true
        echo "$CHOICES" | grep -q "4" && do_hyprland=true
        echo "$CHOICES" | grep -q "5" && do_gnome=true
        echo "$CHOICES" | grep -q "6" && do_steam=true
        echo "$CHOICES" | grep -q "7" && do_waybar=true
        echo "$CHOICES" | grep -q "8" && do_saves=true
    fi
fi

echo ""
log "Proceeding with installation..."
echo ""

# =============================================================================
# FEDORA: Check dnf and rpm fusion availability
if [ "$DISTRO" = "fedora" ]; then
    command -v dnf &>/dev/null || error "dnf not found — are you sure this is Fedora?"
    log "Fedora $FEDORA_VER detected — using dnf + RPM Fusion."
fi

# ARCH: Install AUR helper if missing
# =============================================================================
if [ "$DISTRO" = "arch" ] && [ -z "$AUR_HELPER" ]; then
    section "Installing paru (AUR helper)"
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/paru.git /tmp/paru-install
    (cd /tmp/paru-install && makepkg -si --noconfirm)
    rm -rf /tmp/paru-install
    AUR_HELPER="paru"
    log "paru installed."
    if [ -f /usr/bin/paru ]; then paru --gendb; fi
fi

# =============================================================================
# MODULE 1 — NVIDIA Driver
# =============================================================================
if $do_nvidia; then
    section "Module 1: NVIDIA Driver Setup"

    if [ "$DISTRO" = "arch" ]; then
        banner "Arch: nvidia-580xx-dkms (Pascal legacy driver)"

        # Blacklist nouveau
        if [ ! -f /etc/modprobe.d/blacklist-nouveau.conf ]; then
            printf "blacklist nouveau\noptions nouveau modeset=0\n" |
                sudo tee /etc/modprobe.d/blacklist-nouveau.conf >/dev/null
            log "nouveau blacklisted."
        else
            warn "nouveau blacklist already exists."
        fi

        # Enable DRM modesetting
        if [ ! -f /etc/modprobe.d/nvidia-drm.conf ]; then
            echo "options nvidia_drm modeset=1 fbdev=1" |
                sudo tee /etc/modprobe.d/nvidia-drm.conf >/dev/null
            log "nvidia DRM modesetting enabled."
        fi

        # Install kernel headers + Intel drivers
        sudo pacman -S --needed --noconfirm \
            linux-zen-headers \
            mesa \
            vulkan-intel \
            intel-media-driver \
            xorg-xwayland \
            wlr-randr \
            bc
        # qt5-wayland and qt6-wayland only needed for Hyprland Qt app support
        # Installing them pulls in full Qt dev tools — skip for GNOME setup
        if [ "$DESKTOP" = "hyprland" ]; then
            sudo pacman -S --needed --noconfirm qt5-wayland qt6-wayland
            log "Qt Wayland support installed for Hyprland."
        fi

        # ── Remove ALL conflicting nvidia packages before installing 580xx ──────
        # nvidia-utils, nvidia-open-dkms, and nvidia conflict with nvidia-580xx-utils
        log "Removing any conflicting NVIDIA packages..."

        for PKG in nvidia-open-dkms nvidia-dkms nvidia nvidia-utils nvidia-settings-daemon; do
            if pacman -Q "$PKG" &>/dev/null; then
                warn "Removing conflicting package: $PKG"
                sudo pacman -Rdd --noconfirm "$PKG" 2>/dev/null || true
            fi
        done

        # Also remove nvidia-utils specifically (conflicts with nvidia-580xx-utils)
        if pacman -Q nvidia-utils &>/dev/null; then
            warn "Removing nvidia-utils (conflicts with nvidia-580xx-utils)..."
            sudo pacman -Rdd --noconfirm nvidia-utils 2>/dev/null || true
        fi

        log "Conflicting packages removed."

        # Install Pascal legacy driver from AUR (always rebuild to get latest patches)
        log "Installing nvidia-580xx-dkms from AUR (may take 5-15 minutes)..."
        $AUR_HELPER -S --needed --noconfirm nvidia-580xx-dkms nvidia-580xx-utils

        # Add nvidia modules to mkinitcpio
        if grep -q "^MODULES=()" /etc/mkinitcpio.conf; then
            sudo sed -i \
                's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' \
                /etc/mkinitcpio.conf
            log "NVIDIA modules added to mkinitcpio."
        elif ! grep -q "nvidia" /etc/mkinitcpio.conf; then
            sudo sed -i \
                's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' \
                /etc/mkinitcpio.conf
            log "NVIDIA modules appended to mkinitcpio."
        fi

        # Remove kms hook if present
        if grep -q " kms" /etc/mkinitcpio.conf; then
            sudo sed -i 's/ kms//' /etc/mkinitcpio.conf
            warn "Removed 'kms' from HOOKS (conflicts with NVIDIA early modesetting)."
        fi

        # Rebuild UKI
        log "Rebuilding initramfs/UKI..."
        sudo mkinitcpio -P
        log "NVIDIA driver setup complete."

    elif [ "$DISTRO" = "debian" ]; then
        banner "Debian: nvidia-driver + dkms"

        # Fix fstab btrfs pass values
        section "Fixing fstab btrfs pass values"
        sudo cp /etc/fstab /etc/fstab.bak.$(date +%Y%m%d_%H%M%S)
        sudo sed -i '/btrfs.*subvol=@[^h]/ s/0\s\+[12]\s*$/0       0/' /etc/fstab
        sudo sed -i '/btrfs.*@home/ s/0\s\+[12]\s*$/0       0/' /etc/fstab
        sudo sed -i '/ntfs/ s/\s\+[12]\s*$/ 0    0/' /etc/fstab
        sudo systemctl daemon-reload
        log "fstab btrfs pass values fixed."

        # Enable non-free repos
        SOURCES="/etc/apt/sources.list"
        if ! grep -q "non-free-firmware" "$SOURCES"; then
            sudo cp "$SOURCES" "${SOURCES}.bak"
            sudo sed -i \
                's/^\(deb.*main\)$/\1 contrib non-free non-free-firmware/' \
                "$SOURCES"
            log "non-free repos enabled."
        fi

        sudo apt update

        # Install prerequisites
        sudo apt install -y \
            dkms \
            linux-headers-$(uname -r) \
            linux-headers-amd64 \
            build-essential \
            btrfs-progs \
            pciutils

        # Blacklist nouveau
        if [ ! -f /etc/modprobe.d/blacklist-nouveau.conf ]; then
            printf "blacklist nouveau\noptions nouveau modeset=0\n" |
                sudo tee /etc/modprobe.d/blacklist-nouveau.conf >/dev/null
            log "nouveau blacklisted."
        fi

        # Enable DRM modesetting
        echo "options nvidia_drm modeset=1 fbdev=1" |
            sudo tee /etc/modprobe.d/nvidia-drm.conf >/dev/null
        log "nvidia DRM modesetting enabled."

        # Install NVIDIA driver
        sudo apt install -y \
            nvidia-driver \
            nvidia-driver-libs \
            nvidia-kernel-dkms \
            nvidia-settings \
            firmware-nvidia-graphics \
            nvidia-smi \
            libgl1-nvidia-glvnd-glx \
            libglx-nvidia0 \
            libnvidia-ml1 \
            nvidia-vdpau-driver \
            glx-alternative-nvidia \
            glx-alternative-mesa \
            vainfo \
            mesa-utils

        # Verify DKMS build
        DKMS_STATUS=$(dkms status 2>/dev/null | grep nvidia || true)
        if echo "$DKMS_STATUS" | grep -q "installed"; then
            log "NVIDIA DKMS module built successfully ✓"
        else
            warn "DKMS status: $DKMS_STATUS"
            warn "May need manual rebuild: sudo dkms autoinstall"
        fi

        # Add btrfs to initramfs
        if ! grep -q "^btrfs" /etc/initramfs-tools/modules 2>/dev/null; then
            echo "btrfs" | sudo tee -a /etc/initramfs-tools/modules >/dev/null
            log "btrfs module added to initramfs."
        fi

        sudo update-initramfs -u -k "$(uname -r)"
        log "Debian NVIDIA driver setup complete."

        # Install hybrid GPU tools
        sudo apt install -y nvidia-settings glx-alternative-nvidia glx-alternative-mesa

        # prime-run function
        if [ ! -f /etc/profile.d/nvidia-prime-offload.sh ]; then
            sudo tee /etc/profile.d/nvidia-prime-offload.sh >/dev/null <<'EOF'
prime-run() {
    __NV_PRIME_RENDER_OFFLOAD=1 \
    __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0 \
    __GLX_VENDOR_LIBRARY_NAME=nvidia \
    __VK_LAYER_NV_optimus=NVIDIA_only \
    "$@"
}
export -f prime-run
EOF
            log "prime-run function installed system-wide."
        fi

        # Disable libvirt
        for SVC in libvirtd libvirt-guests virtlogd virtlockd; do
            systemctl is-enabled "$SVC" &>/dev/null &&
                sudo systemctl disable "$SVC" 2>/dev/null || true
        done
        sudo systemctl mask libvirt-guests 2>/dev/null || true
        log "libvirt services disabled."
    elif [ "$DISTRO" = "fedora" ]; then
        banner "Fedora: akmod-nvidia-580xx (Pascal legacy driver)"

        # Update system first
        log "Updating Fedora system..."
        sudo dnf update -y

        # Enable RPM Fusion free and non-free repos
        FEDORA_VER_NUM=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        if ! dnf repolist | grep -q "rpmfusion-nonfree"; then
            log "Enabling RPM Fusion repositories..."
            sudo dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER_NUM}.noarch.rpm" "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER_NUM}.noarch.rpm"
            log "RPM Fusion enabled."
        else
            warn "RPM Fusion already enabled."
        fi

        # Install kernel headers + development tools
        sudo dnf install -y kernel-devel kernel-headers gcc make dkms mesa-libGL mesa-vulkan-drivers vulkan-loader

        # Check if Pascal legacy branch is needed (Fedora 44+)
        if [ "$FEDORA_VER_NUM" -ge 44 ] 2>/dev/null; then
            warn "Fedora $FEDORA_VER_NUM detected — Pascal GPU requires 580xx legacy branch."

            # Remove main akmod-nvidia if installed (conflicts with legacy)
            if rpm -q akmod-nvidia &>/dev/null; then
                warn "Removing main akmod-nvidia (conflicts with 580xx legacy)..."
                sudo dnf remove -y akmod-nvidia xorg-x11-drv-nvidia\* kmod-nvidia\* 2>/dev/null || true
            fi

            # Install legacy 580xx branch
            log "Installing akmod-nvidia-580xx (Pascal legacy driver)..."
            sudo dnf install -y akmod-nvidia-580xx xorg-x11-drv-nvidia-580xx xorg-x11-drv-nvidia-580xx-libs xorg-x11-drv-nvidia-580xx-libs.i686 xorg-x11-drv-nvidia-580xx-cuda 2>/dev/null || sudo dnf install -y akmod-nvidia-580xx xorg-x11-drv-nvidia-580xx

        else
            warn "Fedora $FEDORA_VER_NUM — using standard akmod-nvidia (Pascal still supported)."
            # Remove legacy if present
            if rpm -q akmod-nvidia-580xx &>/dev/null; then
                sudo dnf remove -y akmod-nvidia-580xx 2>/dev/null || true
            fi
            sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-libs.i686
        fi

        # Wait for akmod to build the kernel module
        # This is critical on Fedora — akmod builds async in background
        log "Waiting for akmod to build NVIDIA kernel module (this may take 2-5 minutes)..."
        sudo akmods --force
        sudo dracut --force
        log "akmod build complete."

        # Add NVIDIA kernel parameters via grubby (Fedora's way)
        # Do NOT use grub2-mkconfig alone — use grubby
        log "Adding nvidia_drm.modeset=1 via grubby..."
        if ! sudo grubby --info=ALL | grep -q "nvidia_drm.modeset=1"; then
            sudo grubby --update-kernel=ALL --args="nvidia_drm.modeset=1 nvidia_drm.fbdev=1"
            log "NVIDIA kernel parameters added via grubby."
        else
            warn "nvidia_drm.modeset=1 already in kernel parameters."
        fi

        # NVIDIA environment variables for Fedora + GNOME Wayland
        sudo mkdir -p /etc/environment.d
        if [ ! -f /etc/environment.d/nvidia-fedora.conf ]; then
            sudo tee /etc/environment.d/nvidia-fedora.conf >/dev/null <<'EOF'
# NVIDIA Wayland env vars for Fedora
LIBVA_DRIVER_NAME=nvidia
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
NVD_BACKEND=direct
EOF
            log "NVIDIA env vars written to /etc/environment.d/nvidia-fedora.conf"
        fi

        # Enable GDM Wayland (make sure it is not disabled)
        GDM_CONF="/etc/gdm/custom.conf"
        if [ -f "$GDM_CONF" ]; then
            if grep -q "^WaylandEnable=false" "$GDM_CONF"; then
                sudo sed -i 's/^WaylandEnable=false/WaylandEnable=true/' "$GDM_CONF"
                log "Wayland re-enabled in GDM config."
            fi
        fi

        # prime-run for per-app GPU selection
        if [ ! -f /etc/profile.d/nvidia-prime-offload.sh ]; then
            sudo tee /etc/profile.d/nvidia-prime-offload.sh >/dev/null <<'EOF'
prime-run() {
    __NV_PRIME_RENDER_OFFLOAD=1     __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0     __GLX_VENDOR_LIBRARY_NAME=nvidia     __VK_LAYER_NV_optimus=NVIDIA_only     "$@"
}
export -f prime-run
EOF
            log "prime-run function installed system-wide."
        fi

        log "Fedora NVIDIA driver setup complete."
    fi
fi

# =============================================================================
# MODULE 2 — nvidia-toggle
# =============================================================================
if $do_toggle; then
    section "Module 2: Installing nvidia-toggle"

    sudo tee /usr/local/bin/nvidia-toggle >/dev/null <<'NVTOGGLE'
#!/bin/bash
# nvidia-toggle v3 — Intel-only / Hybrid GPU switching
# Supports: Arch Linux (UKI + standard) + Debian 13
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }
section() { echo -e "\n${BLUE}══════════════════════════════════════════${NC}\n${BLUE}  $1${NC}\n${BLUE}══════════════════════════════════════════${NC}"; }
[ "$EUID" -eq 0 ] && echo -e "${RED}[✗]${NC} Do not run as root." && exit 1
grep -qi "arch" /etc/os-release 2>/dev/null && DISTRO="arch" || DISTRO="debian"
DISABLE_CONF="/etc/modprobe.d/disable-nvidia.conf"
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
KERNEL_CMDLINE="/etc/kernel/cmdline"
NVIDIA_CMDLINE_PARAMS="module_blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm"
is_uki() { [ -f "$KERNEL_CMDLINE" ]; }
rebuild() {
    log "Rebuilding initramfs..."
    if [ "$DISTRO" = "arch" ]; then
        sudo mkinitcpio -P
    elif [ "$DISTRO" = "debian" ]; then
        sudo update-initramfs -u -k "$(uname -r)"
    elif [ "$DISTRO" = "fedora" ]; then
        sudo dracut --force
        log "dracut initramfs rebuilt."
    fi
}
get_mode() {
    { [ -f "$DISABLE_CONF" ] || { is_uki && grep -q "module_blacklist" "$KERNEL_CMDLINE" 2>/dev/null; }; } && echo "intel" || echo "hybrid"
}
show_status() {
    section "Current GPU Status"
    MODE=$(get_mode)
    NV=$(lsmod | grep -c "^nvidia " 2>/dev/null || echo 0)
    I9=$(lsmod | grep -c "^i915" 2>/dev/null || echo 0)
    NV=${NV:-0}; I9=${I9:-0}
    echo ""
    [ "$MODE" = "intel" ] && echo -e "  Mode: ${YELLOW}Intel Only${NC}" || echo -e "  Mode: ${GREEN}Hybrid${NC}"
    echo ""
    [ "$I9" -gt 0 ] && echo -e "  Intel i915:    ${GREEN}loaded ✓${NC}" || echo -e "  Intel i915:    ${RED}not loaded${NC}"
    if [ "$NV" -gt 0 ]; then
        [ "$MODE" = "intel" ] && echo -e "  NVIDIA Quadro: ${YELLOW}loaded (disable after reboot)${NC}" \
                              || echo -e "  NVIDIA Quadro: ${GREEN}loaded ✓${NC}"
    else
        [ "$MODE" = "intel" ] && echo -e "  NVIDIA Quadro: ${GREEN}not loaded ✓ (Intel-only active)${NC}" \
                              || echo -e "  NVIDIA Quadro: ${RED}not loaded${NC}"
    fi
    echo ""
    command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null 2>&1 && \
        nvidia-smi --query-gpu=name,driver_version,utilization.gpu,temperature.gpu \
            --format=csv,noheader 2>/dev/null | \
            awk -F',' '{printf "  GPU: %s | Driver: %s | Usage: %s | Temp: %s°C\n",$1,$2,$3,$4}'
    is_uki && { echo ""; info "UKI cmdline: $(cat $KERNEL_CMDLINE)"; }
    echo ""
    info "  nvidia-toggle intel  → Intel only (reboot required)"
    info "  nvidia-toggle hybrid → Hybrid mode (reboot required)"
}
switch_intel() {
    section "Switching to Intel-Only Mode"
    warn "This will DISABLE the NVIDIA Quadro P3200. Reboot required."
    read -rp "Continue? [y/N] " c; [[ "$c" =~ ^[Yy]$ ]] || exit 0
    sudo tee "$DISABLE_CONF" > /dev/null << 'EOF'
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nvidia_uvm
blacklist nvidia_agp
EOF
    if [ "$DISTRO" = "arch" ]; then
        if is_uki; then
            sudo cp "$KERNEL_CMDLINE" "${KERNEL_CMDLINE}.nvtog-bak"
            grep -q "module_blacklist" "$KERNEL_CMDLINE" || \
                sudo bash -c "echo -n ' $NVIDIA_CMDLINE_PARAMS' >> '$KERNEL_CMDLINE'"
            log "module_blacklist added to /etc/kernel/cmdline"
        fi
        if [ -f "$MKINITCPIO_CONF" ] && grep -q "nvidia" "$MKINITCPIO_CONF"; then
            sudo cp "$MKINITCPIO_CONF" "${MKINITCPIO_CONF}.nvtog-bak"
            sudo sed -i 's/^MODULES=(.*/MODULES=()/' "$MKINITCPIO_CONF"
            log "Cleared nvidia from mkinitcpio MODULES"
        fi
    fi
    echo "intel" | sudo tee /etc/nvidia-toggle-status > /dev/null
    rebuild
    log "Done. Reboot to apply."
    read -rp "Reboot now? [Y/n] " r; r=${r:-Y}; [[ "$r" =~ ^[Yy]$ ]] && sudo reboot
}
switch_hybrid() {
    section "Switching to Hybrid Mode"
    [ -f "$DISABLE_CONF" ] && sudo rm "$DISABLE_CONF" && log "Blacklist removed."
    if [ "$DISTRO" = "arch" ]; then
        if is_uki; then
            if [ -f "${KERNEL_CMDLINE}.nvtog-bak" ]; then
                sudo cp "${KERNEL_CMDLINE}.nvtog-bak" "$KERNEL_CMDLINE"
                log "Restored /etc/kernel/cmdline"
            else
                sudo sed -i "s| $NVIDIA_CMDLINE_PARAMS||g" "$KERNEL_CMDLINE"
            fi
        fi
        if [ -f "${MKINITCPIO_CONF}.nvtog-bak" ]; then
            sudo cp "${MKINITCPIO_CONF}.nvtog-bak" "$MKINITCPIO_CONF"
            log "mkinitcpio.conf restored"
        else
            grep -q "nvidia" "$MKINITCPIO_CONF" || \
                sudo sed -i \
                's/^MODULES=(.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' \
                "$MKINITCPIO_CONF"
        fi
    fi
    echo "hybrid" | sudo tee /etc/nvidia-toggle-status > /dev/null
    rebuild
    log "Done. Reboot to apply."
    read -rp "Reboot now? [Y/n] " r; r=${r:-Y}; [[ "$r" =~ ^[Yy]$ ]] && sudo reboot
}
case "${1:-status}" in
    intel)         switch_intel  ;;
    hybrid|nvidia) switch_hybrid ;;
    status|"")     show_status   ;;
    *) echo "Usage: nvidia-toggle [intel|hybrid|status]"; exit 1 ;;
esac
NVTOGGLE

    sudo chmod +x /usr/local/bin/nvidia-toggle
    log "nvidia-toggle installed to /usr/local/bin/nvidia-toggle"
fi

# =============================================================================
# MODULE 3 — Pacman Hook (Arch only)
# =============================================================================
if $do_hook && [ "$DISTRO" = "arch" ]; then
    section "Module 3: Pacman NVIDIA DKMS Hook"

    sudo mkdir -p /etc/pacman.d/hooks
    sudo tee /etc/pacman.d/hooks/nvidia-dkms-rebuild.hook >/dev/null <<'EOF'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux-zen
Target = linux-zen-headers

[Action]
Description = Rebuilding NVIDIA DKMS module and UKI after kernel update...
When = PostTransaction
Exec = /usr/bin/bash -c 'dkms autoinstall -k $(uname -r) && mkinitcpio -p linux-zen && exit 0; echo "DKMS build failed — run: paru -S nvidia-580xx-dkms --rebuild && sudo mkinitcpio -p linux-zen"'
Depends = mkinitcpio
Depends = dkms
EOF
    log "Pacman hook installed at /etc/pacman.d/hooks/nvidia-dkms-rebuild.hook"
elif $do_hook && [ "$DISTRO" != "arch" ]; then
    skip "Pacman hook (Arch only)"
fi

# =============================================================================
# MODULE 4 — Hyprland Config (Arch only)
# =============================================================================
if $do_hyprland && [ "$DISTRO" = "arch" ]; then
    section "Module 4: Hyprland Configuration"

    HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
    mkdir -p "$HOME/.config/hypr"
    [ ! -f "$HYPR_CONF" ] && touch "$HYPR_CONF"

    # NVIDIA env vars
    if ! grep -q "GBM_BACKEND" "$HYPR_CONF"; then
        cat >>"$HYPR_CONF" <<'EOF'

# ── NVIDIA Wayland environment variables ──────────────────────────────────────
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = WLR_NO_HARDWARE_CURSORS,1
env = NVD_BACKEND,direct
# NOTE: __GLX_VENDOR_LIBRARY_NAME is NOT set globally
# Set per-game in Steam launch options instead:
# __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia %command%
EOF
        log "NVIDIA env vars added to hyprland.conf"
    fi

    # Monitor config
    if ! grep -q "^monitor = eDP-1" "$HYPR_CONF"; then
        cat >>"$HYPR_CONF" <<'EOF'

# ── Monitor configuration ─────────────────────────────────────────────────────
# Laptop screen
monitor = eDP-1, 1920x1080@60, 0x0, 1
# External HDMI — mirror mode
monitor = HDMI-A-1, preferred, 0x0, 1, mirror, eDP-1
# Fallback for any other display
monitor = ,preferred,auto,1
EOF
        log "Monitor config added to hyprland.conf"
    fi

    # Steam runtime env
    if ! grep -q "STEAM_RUNTIME" "$HYPR_CONF"; then
        cat >>"$HYPR_CONF" <<'EOF'

# ── Steam / Gaming ─────────────────────────────────────────────────────────────
env = STEAM_RUNTIME,1
EOF
        log "Steam env added to hyprland.conf"
    fi

    # Workspace rules
    if ! grep -q "steam_app_" "$HYPR_CONF"; then
        cat >>"$HYPR_CONF" <<'EOF'

# ── Workspace rules ───────────────────────────────────────────────────────────
# Steam client → workspace 9, auto-switch
windowrule = workspace 9, match:class ^(steam)$
# Steam games → workspace 10, fullscreen
windowrule = workspace 10, match:class ^(steam_app_.*)$
windowrule = fullscreen, match:class ^(steam_app_.*)$

# ── Keybinds for game workspaces ──────────────────────────────────────────────
bind = SUPER, S, workspace, 9
bind = SUPER, G, workspace, 10
EOF
        log "Workspace rules added to hyprland.conf"
    fi

elif $do_hyprland && [ "$DISTRO" != "arch" ]; then
    skip "Hyprland config (Arch only)"
fi

# =============================================================================
# MODULE 5 — GNOME Config
# =============================================================================
if $do_gnome; then
    section "Module 5: GNOME Configuration"

    if [ "$DISTRO" = "arch" ]; then
        banner "Arch: GNOME 50 setup"

        # Install GNOME
        sudo pacman -S --needed --noconfirm \
            gnome-tweaks \
            gdm \
            xdg-desktop-portal \
            xdg-desktop-portal-gnome \
            pipewire pipewire-pulse pipewire-alsa wireplumber

        sudo systemctl enable gdm
        log "GNOME installed and GDM enabled."

        # NVIDIA env vars for GNOME 50 (Wayland-only — no WaylandEnable needed)
        sudo mkdir -p /etc/environment.d
        if [ ! -f /etc/environment.d/nvidia-gnome.conf ]; then
            sudo tee /etc/environment.d/nvidia-gnome.conf >/dev/null <<'EOF'
# NVIDIA Wayland env vars for GNOME 50
# GNOME 50 is Wayland-only — no WaylandEnable needed in GDM
LIBVA_DRIVER_NAME=nvidia
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
NVD_BACKEND=direct
EOF
            log "NVIDIA env vars written to /etc/environment.d/nvidia-gnome.conf"
        fi

    elif [ "$DISTRO" = "fedora" ]; then
        banner "Fedora: GNOME config"

        # Fedora ships GNOME by default — just ensure env vars are set
        sudo mkdir -p /etc/environment.d
        if [ ! -f /etc/environment.d/nvidia-gnome.conf ]; then
            sudo tee /etc/environment.d/nvidia-gnome.conf >/dev/null <<'EOF'
LIBVA_DRIVER_NAME=nvidia
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
NVD_BACKEND=direct
EOF
            log "NVIDIA GNOME env vars written."
        fi

        # Ensure GDM Wayland is not disabled
        GDM_CONF="/etc/gdm/custom.conf"
        if [ -f "$GDM_CONF" ] && grep -q "^WaylandEnable=false" "$GDM_CONF"; then
            sudo sed -i 's/^WaylandEnable=false/WaylandEnable=true/' "$GDM_CONF"
            log "Wayland re-enabled in GDM."
        fi

        # HDMI mirror autostart
        HDMI_SCRIPT="$HOME/.local/bin/hdmi-mirror"
        mkdir -p "$HOME/.local/bin"
        if [ ! -f "$HDMI_SCRIPT" ]; then
            cat >"$HDMI_SCRIPT" <<'MIRRORSCRIPT'
#!/bin/bash
PRIMARY=$(xrandr 2>/dev/null | grep " connected primary" | awk "{print \$1}")
PRIMARY=${PRIMARY:-eDP-1}
HDMI_OUT=$(xrandr 2>/dev/null | grep " connected" | grep -v primary | awk "{print \$1}" | head -1)
[ -z "$HDMI_OUT" ] && exit 0
xrandr --output "$PRIMARY" --auto --pos 0x0 --output "$HDMI_OUT" --same-as "$PRIMARY" --auto
MIRRORSCRIPT
            chmod +x "$HDMI_SCRIPT"
        fi
        mkdir -p "$HOME/.config/autostart"
        cat >"$HOME/.config/autostart/hdmi-mirror.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=HDMI Mirror
Exec=/bin/bash -c "sleep 3 && $HDMI_SCRIPT"
X-GNOME-Autostart-enabled=true
EOF
        log "HDMI mirror autostart created for Fedora."

    elif [ "$DISTRO" = "debian" ]; then
        banner "Debian: GNOME config + HDMI autostart"

        # Install GNOME essentials if missing
        sudo apt install -y --no-install-recommends \
            gnome-session gnome-shell gnome-settings-daemon \
            gdm3 xdg-user-dirs xdg-desktop-portal \
            xdg-desktop-portal-gnome pipewire pipewire-pulse \
            pipewire-alsa wireplumber

        sudo systemctl enable gdm3 2>/dev/null || sudo systemctl enable gdm 2>/dev/null || true

        # NVIDIA env for Debian GNOME
        sudo mkdir -p /etc/environment.d
        if [ ! -f /etc/environment.d/nvidia-gnome.conf ]; then
            sudo tee /etc/environment.d/nvidia-gnome.conf >/dev/null <<'EOF'
LIBVA_DRIVER_NAME=nvidia
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
__NV_PRIME_RENDER_OFFLOAD=1
__VK_LAYER_NV_optimus=NVIDIA_only
NVD_BACKEND=direct
EOF
            log "NVIDIA env vars written to /etc/environment.d/nvidia-gnome.conf"
        fi

        # Remove udev HDMI rule (causes /home unmount failure)
        UDEV_RULE="/etc/udev/rules.d/95-hdmi-mirror.rules"
        if [ -f "$UDEV_RULE" ]; then
            sudo rm "$UDEV_RULE"
            sudo udevadm control --reload-rules
            log "Removed udev HDMI auto-mirror rule (was causing /home unmount failure)."
        fi

        # HDMI mirror via GNOME autostart (safe)
        HDMI_SCRIPT="$HOME/.local/bin/hdmi-mirror"
        mkdir -p "$HOME/.local/bin"
        if [ ! -f "$HDMI_SCRIPT" ]; then
            cat >"$HDMI_SCRIPT" <<'MIRRORSCRIPT'
#!/bin/bash
PRIMARY=$(xrandr 2>/dev/null | grep ' connected primary' | awk '{print $1}')
PRIMARY=${PRIMARY:-eDP-1}
HDMI_OUT=$(xrandr 2>/dev/null | grep ' connected' | grep -v primary | awk '{print $1}' | head -1)
[ -z "$HDMI_OUT" ] && exit 0
xrandr --output "$PRIMARY" --auto --pos 0x0 \
       --output "$HDMI_OUT" --same-as "$PRIMARY" --auto
MIRRORSCRIPT
            chmod +x "$HDMI_SCRIPT"
            log "hdmi-mirror script created."
        fi

        mkdir -p "$HOME/.config/autostart"
        cat >"$HOME/.config/autostart/hdmi-mirror.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=HDMI Mirror
Exec=/bin/bash -c 'sleep 3 && $HDMI_SCRIPT'
X-GNOME-Autostart-enabled=true
EOF
        log "HDMI mirror autostart created."
    fi
fi

# =============================================================================
# MODULE 6 — Steam (Flatpak — unified across all distros)
# =============================================================================
if $do_steam; then
    section "Module 6: Steam via Flatpak (all distros)"

    banner "Steam — Flatpak + Shared Storage"

    # ── Step 1: Set up shared Flatpak storage on external drive ──────────────
    # ~/.var/app is where Flatpak stores ALL app data (Steam, ProtonUp, etc.)
    # Symlinking it to the storage drive means:
    #   - All Flatpak apps persist across distro reinstalls
    #   - Steam games, settings, Proton versions shared across all distros
    #   - Clean home directory

    FLATPAK_HOME="$HOME/.var"
    FLATPAK_STORAGE_FULL="$FLATPAK_STORAGE"

    echo ""
    info "Flatpak shared storage plan:"
    info "  Symlink: $FLATPAK_HOME → $FLATPAK_STORAGE_FULL"
    info "  All Flatpak app data will live on your storage drive."
    info "  Steam, saves, Proton versions — shared across all distros."
    echo ""

    if [ ! -d "$(dirname "$FLATPAK_STORAGE_FULL")" ]; then
        warn "Storage drive path not found: $FLATPAK_STORAGE_FULL"
        warn "Make sure /media/$USER/Storage/Apps is accessible."
        warn "Skipping Flatpak storage symlink — re-run option 6 after mounting."
    else
        mkdir -p "$FLATPAK_STORAGE_FULL/app"
        log "Flatpak storage directory ready: $FLATPAK_STORAGE_FULL"

        if [ -L "$FLATPAK_HOME" ]; then
            CURRENT_TARGET=$(readlink -f "$FLATPAK_HOME")
            if [ "$CURRENT_TARGET" = "$FLATPAK_STORAGE_FULL" ]; then
                warn "~/.var already correctly symlinked to storage drive."
            else
                warn "~/.var is a symlink pointing to: $CURRENT_TARGET"
                read -rp "  Re-link to $FLATPAK_STORAGE_FULL? [Y/n] " relink
                relink=${relink:-Y}
                if [[ "$relink" =~ ^[Yy]$ ]]; then
                    rm "$FLATPAK_HOME"
                    # ln -s "$FLATPAK_STORAGE_FULL" "$FLATPAK_HOME"
                    log "~/.var re-linked to $FLATPAK_STORAGE_FULL"
                fi
            fi
        elif [ -d "$FLATPAK_HOME" ]; then
            log "Existing ~/.var found — migrating to storage drive..."
            BACKUP="$HOME/.var.backup.$(date +%Y%m%d_%H%M%S)"
            cp -r "$FLATPAK_HOME" "$BACKUP"
            log "Backup: $BACKUP"
            cp -rn "$FLATPAK_HOME/." "$FLATPAK_STORAGE_FULL/" 2>/dev/null || true
            rm -rf "$FLATPAK_HOME"
            # ln -s "$FLATPAK_STORAGE_FULL" "$FLATPAK_HOME"
            log "~/.var migrated and symlinked → $FLATPAK_STORAGE_FULL"
        else
            # ln -s "$FLATPAK_STORAGE_FULL" "$FLATPAK_HOME"
            log "~/.var symlinked to storage drive (fresh state)."
        fi

        [ -L "$FLATPAK_HOME" ] && log "~/.var symlink verified: $(readlink -f $FLATPAK_HOME)" || warn "Symlink verification failed — check manually."
    fi

    # ── Step 2: Install Flatpak per distro ────────────────────────────────────
    if [ "$DISTRO" = "arch" ]; then
        sudo pacman -S --needed --noconfirm flatpak xdg-user-dirs
        log "Flatpak installed on Arch."

        # Enable multilib if not already
        if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
            sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
            sudo pacman -Sy
            log "multilib enabled."
        fi

        # lib32-nvidia-580xx-utils FIRST to prevent vulkan conflict
        if ! pacman -Q lib32-nvidia-580xx-utils &>/dev/null; then
            log "Installing lib32-nvidia-580xx-utils (prevents vulkan conflict)..."
            $AUR_HELPER -S --needed --noconfirm lib32-nvidia-580xx-utils
        fi

        sudo pacman -S --needed --noconfirm \
            lib32-mesa lib32-vulkan-icd-loader vulkan-icd-loader \
            lib32-alsa-plugins lib32-libpulse lib32-pipewire \
            pipewire pipewire-pulse pipewire-alsa wireplumber \
            gamemode lib32-gamemode

        systemctl --user enable gamemoded 2>/dev/null || true
        xdg-user-dirs-update

    elif [ "$DISTRO" = "debian" ]; then
        sudo apt install -y flatpak gnome-software-plugin-flatpak
        log "Flatpak installed on Debian."

    elif [ "$DISTRO" = "fedora" ]; then
        sudo dnf install -y flatpak
        log "Flatpak installed on Fedora."
    fi

    # ── Step 3: Add Flathub ───────────────────────────────────────────────────
    flatpak remotes | grep -q "flathub" && warn "Flathub already added." || {
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        log "Flathub repository added."
    }

    # ── Step 4: Install Steam + protonUp-Qt ───────────────────────────────────
    if flatpak list | grep -q "com.valvesoftware.Steam"; then
        warn "Steam Flatpak already installed (data on storage drive)."
    else
        log "Installing Steam via Flatpak..."
        flatpak install -y flathub com.valvesoftware.Steam
        log "Steam installed."
    fi

    # flatpak list | grep -q "net.davidotek.pupgui2" || {
    #     flatpak install -y flathub net.davidotek.pupgui2 2>/dev/null || true
    #     log "ProtonUp-Qt installed."
    # }

    # ── Step 5: Grant Flatpak permissions ────────────────────────────────────
    flatpak override --user --device=dri com.valvesoftware.Steam
    flatpak override --user --filesystem=/run/media com.valvesoftware.Steam
    flatpak override --user --filesystem=/media com.valvesoftware.Steam
    [ -d "$STORAGE_PATH" ] && flatpak override --user --filesystem="$STORAGE_PATH" com.valvesoftware.Steam
    [ -d "$FLATPAK_STORAGE" ] && flatpak override --user --filesystem="$FLATPAK_STORAGE" com.valvesoftware.Steam

    # Remove global PRIME overrides — use per-game launch options instead
    flatpak override --user --unset-env=__NV_PRIME_RENDER_OFFLOAD --unset-env=__GLX_VENDOR_LIBRARY_NAME com.valvesoftware.Steam 2>/dev/null || true

    # ── Step 6: Install steam-devices udev rules on host ─────────────────────
    # Steam Flatpak cannot install udev rules itself (requires root outside sandbox)
    # These rules enable gamepad/controller support for Steam input devices
    section "Installing steam-devices udev rules"

    if [ "$DISTRO" = "arch" ]; then
        # steam-devices-git from AUR
        # Note: only needed when using Flatpak Steam
        # (native steam package already includes these rules)
        if ! pacman -Q steam-devices-git &>/dev/null && ! pacman -Q steam &>/dev/null; then
            log "Installing steam-devices udev rules from AUR..."
            $AUR_HELPER -S --needed --noconfirm steam-devices-git
        else
            warn "steam-devices rules already provided by installed packages."
        fi

    elif [ "$DISTRO" = "debian" ]; then
        if ! dpkg -l steam-devices &>/dev/null 2>&1; then
            log "Installing steam-devices udev rules..."
            sudo apt install -y steam-devices 2>/dev/null || {
                warn "steam-devices package not found in apt — downloading from Valve directly..."
                sudo curl -fsSL -o /etc/udev/rules.d/60-steam-input.rules https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules
                sudo curl -fsSL -o /etc/udev/rules.d/60-steam-vr.rules https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-vr.rules
                log "Steam udev rules installed from Valve GitHub."
            }
        else
            warn "steam-devices already installed."
        fi

    elif [ "$DISTRO" = "fedora" ]; then
        if ! rpm -q steam-devices &>/dev/null 2>&1; then
            log "Installing steam-devices udev rules from Valve GitHub..."
            sudo curl -fsSL -o /etc/udev/rules.d/60-steam-input.rules https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules
            sudo curl -fsSL -o /etc/udev/rules.d/60-steam-vr.rules https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-vr.rules
            log "Steam udev rules installed."
        else
            warn "steam-devices rules already installed."
        fi
    fi

    # Reload udev rules to apply immediately (no reboot needed)
    if [ -f /etc/udev/rules.d/60-steam-input.rules ]; then
        sudo udevadm control --reload-rules
        sudo udevadm trigger
        log "udev rules reloaded — gamepad/controller support active."
    fi

    # ── Step 7: steam terminal shortcut ──────────────────────────────────────
    mkdir -p "$HOME/.local/bin"
    cat >"$HOME/.local/bin/steam" <<'STEAMEOF'
#!/bin/bash
exec flatpak run com.valvesoftware.Steam "$@"
STEAMEOF
    chmod +x "$HOME/.local/bin/steam"

    echo ""
    log "Steam setup complete."
    info "  ~/.var → $FLATPAK_STORAGE (shared across all distros)"
    info "  Per-game Quadro: __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia %command%"
fi

# =============================================================================
# MODULE 7 — Waybar modules (Arch + Hyprland only)
# =============================================================================
if $do_waybar && [ "$DISTRO" = "arch" ]; then
    section "Module 7: Waybar GPU / Fan / Temperature Modules"

    sudo pacman -S --needed --noconfirm waybar bc lm_sensors

    # Load dell_smm_hwmon
    sudo modprobe dell-smm-hwmon 2>/dev/null || true
    if ! grep -q "dell-smm-hwmon" /etc/modules-load.d/*.conf 2>/dev/null; then
        echo "dell-smm-hwmon" | sudo tee /etc/modules-load.d/dell-smm-hwmon.conf >/dev/null
    fi
    sudo systemctl enable --now lm_sensors 2>/dev/null || true

    SCRIPT_DIR="$HOME/.config/waybar/scripts"
    mkdir -p "$SCRIPT_DIR"

    # GPU script
    cat >"$SCRIPT_DIR/nvidia-gpu.sh" <<'GPUSCRIPT'
#!/bin/bash
if ! command -v nvidia-smi &>/dev/null || ! nvidia-smi &>/dev/null 2>&1; then
    echo '{"text": "󰍛 Intel", "tooltip": "Running on Intel iGPU", "class": "gpu-intel"}'
    exit 0
fi
GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
VRAM_USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
GPU_POWER=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ' | cut -d'.' -f1)
DRIVER_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
VRAM_USED_G=$(echo "scale=1; $VRAM_USED / 1024" | bc 2>/dev/null || echo "?")
GPU_UTIL=${GPU_UTIL:-0}
[ "$GPU_UTIL" -gt 3 ] 2>/dev/null && ACTIVE_MODE="quadro" || ACTIVE_MODE="intel"
[ "$GPU_TEMP" -ge 85 ] 2>/dev/null && WARN=" 🔥" || { [ "$GPU_TEMP" -ge 75 ] 2>/dev/null && WARN=" ⚠" || WARN=""; }
if [ "$ACTIVE_MODE" = "quadro" ]; then
    [ "$GPU_UTIL" -ge 80 ] 2>/dev/null && CLASS="gpu-high" || { [ "$GPU_UTIL" -ge 40 ] 2>/dev/null && CLASS="gpu-medium" || CLASS="gpu-low"; }
    TEXT="󰍛 Quadro ${GPU_UTIL}%  ${VRAM_USED_G}G${WARN}"
else
    CLASS="gpu-intel"; TEXT="󰍛 Intel"
fi
TOOLTIP="Mode: ${ACTIVE_MODE}\\nUsage: ${GPU_UTIL}%\\nVRAM: ${VRAM_USED_G}G\\nTemp: ${GPU_TEMP}°C${WARN}\\nPower: ${GPU_POWER}W\\nDriver: ${DRIVER_VER}"
printf '{"text": "%s", "tooltip": "%s", "class": "%s", "percentage": %s}\n' "$TEXT" "$TOOLTIP" "$CLASS" "${GPU_UTIL:-0}"
GPUSCRIPT
    chmod +x "$SCRIPT_DIR/nvidia-gpu.sh"

    # Fan script
    cat >"$SCRIPT_DIR/fan-speed.sh" <<'FANSCRIPT'
#!/bin/bash
if ! command -v sensors &>/dev/null; then
    echo '{"text": "󰈐 N/A", "tooltip": "lm_sensors not installed", "class": "fan-offline"}'
    exit 0
fi
DELL_SMM=$(sensors dell_smm-isa-00de 2>/dev/null)
[ -z "$DELL_SMM" ] && echo '{"text": "󰈐 N/A", "class": "fan-offline"}' && exit 0
FAN1=$(echo "$DELL_SMM" | awk '/^fan1:/ {print $2}'); FAN1=${FAN1:-0}
FAN2=$(echo "$DELL_SMM" | awk '/^fan2:/ {print $2}'); FAN2=${FAN2:-0}
MAX_FAN=$(( FAN1 > FAN2 ? FAN1 : FAN2 ))
FAN1_PCT=$(echo "scale=0; $FAN1 * 100 / 4200" | bc 2>/dev/null || echo "0")
CPU_TEMP=$(sensors coretemp-isa-0000 2>/dev/null | awk '/^Package id 0:/ {gsub(/[^0-9.]/, "", $4); print int($4)}')
[ "$CPU_TEMP" -ge 90 ] 2>/dev/null && WARN=" 🔥" || { [ "$CPU_TEMP" -ge 80 ] 2>/dev/null && WARN=" ⚠" || WARN=""; }
[ "$MAX_FAN" -ge 3500 ] 2>/dev/null && CLASS="fan-high" || { [ "$MAX_FAN" -ge 2500 ] 2>/dev/null && CLASS="fan-medium" || { [ "$MAX_FAN" -ge 1000 ] 2>/dev/null && CLASS="fan-low" || CLASS="fan-idle"; }; }
fmt_rpm() { [ "$1" -ge 1000 ] 2>/dev/null && echo "scale=1; $1 / 1000" | bc | sed 's/\.0$//' | xargs -I{} echo "{}k" || echo "$1"; }
F1=$(fmt_rpm "$FAN1"); F2=$(fmt_rpm "$FAN2")
TEXT="󰈐 ${F1}  ${F2}${WARN}"
TOOLTIP="CPU Fan: ${FAN1} RPM (${FAN1_PCT}%)\\nGPU Fan: ${FAN2} RPM\\nCPU Temp: ${CPU_TEMP}°C${WARN}"
printf '{"text": "%s", "tooltip": "%s", "class": "%s", "percentage": %s}\n' "$TEXT" "$TOOLTIP" "$CLASS" "${FAN1_PCT:-0}"
FANSCRIPT
    chmod +x "$SCRIPT_DIR/fan-speed.sh"

    # Temperature script
    cat >"$SCRIPT_DIR/temp-monitor.sh" <<'TEMPSCRIPT'
#!/bin/bash
if ! command -v sensors &>/dev/null; then
    echo '{"text": " N/A", "class": "temp-offline"}'; exit 0
fi
CPU_PKG=$(sensors coretemp-isa-0000 2>/dev/null | awk '/^Package id 0:/ {gsub(/[^0-9.]/, "", $4); print int($4)}')
CPU_PKG=${CPU_PKG:-0}
GPU_TEMP=$(command -v nvidia-smi &>/dev/null && nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ' || echo "")
NVME1=$(sensors nvme-pci-0300 2>/dev/null | awk '/^Composite:/ {gsub(/[^0-9.]/, "", $2); print int($2)}')
[ "$CPU_PKG" -ge 90 ] 2>/dev/null && CLASS="temp-critical" || { [ "$CPU_PKG" -ge 80 ] 2>/dev/null && CLASS="temp-high" || { [ "$CPU_PKG" -ge 70 ] 2>/dev/null && CLASS="temp-warm" || { [ "$CPU_PKG" -ge 50 ] 2>/dev/null && CLASS="temp-normal" || CLASS="temp-cool"; }; }; }
[ "$CPU_PKG" -ge 90 ] 2>/dev/null && WARN=" 🔥" || { [ "$CPU_PKG" -ge 80 ] 2>/dev/null && WARN=" ⚠" || WARN=""; }
TEXT=" ${CPU_PKG}°C${WARN}"
TOOLTIP="CPU Package: ${CPU_PKG}°C${WARN}"
[ -n "$GPU_TEMP" ] && TOOLTIP="${TOOLTIP}\\nGPU: ${GPU_TEMP}°C"
[ -n "$NVME1" ] && TOOLTIP="${TOOLTIP}\\nNVMe: ${NVME1}°C"
printf '{"text": "%s", "tooltip": "%s", "class": "%s", "percentage": %s}\n' "$TEXT" "$TOOLTIP" "$CLASS" "${CPU_PKG:-0}"
TEMPSCRIPT
    chmod +x "$SCRIPT_DIR/temp-monitor.sh"

    # Add CSS to waybar style.css
    WAYBAR_CSS="$HOME/.config/waybar/style.css"
    touch "$WAYBAR_CSS"

    grep -q "custom-nvidia-gpu" "$WAYBAR_CSS" || cat >>"$WAYBAR_CSS" <<'CSS'

/* ── GPU Module ──────────────────────────────────────────────────────────── */
#custom-nvidia-gpu { font-size:13px; padding:0 10px; border-radius:6px; margin:3px 2px; font-weight:bold; transition:all 0.3s; }
#custom-nvidia-gpu.gpu-intel  { color:#89b4fa; background:transparent; }
#custom-nvidia-gpu.gpu-low    { color:#a6e3a1; background:rgba(166,227,161,0.1); }
#custom-nvidia-gpu.gpu-medium { color:#f9e2af; background:rgba(249,226,175,0.15); }
#custom-nvidia-gpu.gpu-high   { color:#f38ba8; background:rgba(243,139,168,0.15); animation:gpupulse 1s ease-in-out infinite alternate; }
#custom-nvidia-gpu.gpu-offline{ color:#45475a; }
@keyframes gpupulse { from{background:rgba(243,139,168,0.10)} to{background:rgba(243,139,168,0.28)} }

/* ── Fan Module ──────────────────────────────────────────────────────────── */
#custom-fan { font-size:13px; padding:0 10px; border-radius:6px; margin:3px 2px; font-weight:bold; }
#custom-fan.fan-idle   { color:#6c7086; }
#custom-fan.fan-low    { color:#a6e3a1; background:rgba(166,227,161,0.1); }
#custom-fan.fan-medium { color:#f9e2af; background:rgba(249,226,175,0.15); }
#custom-fan.fan-high   { color:#f38ba8; background:rgba(243,139,168,0.15); animation:fanpulse 0.8s ease-in-out infinite alternate; }
@keyframes fanpulse { from{background:rgba(243,139,168,0.10)} to{background:rgba(243,139,168,0.28)} }

/* ── Temp Module ─────────────────────────────────────────────────────────── */
#custom-temp { font-size:13px; padding:0 10px; border-radius:6px; margin:3px 2px; font-weight:bold; }
#custom-temp.temp-cool     { color:#89dceb; }
#custom-temp.temp-normal   { color:#a6e3a1; background:rgba(166,227,161,0.1); }
#custom-temp.temp-warm     { color:#f9e2af; background:rgba(249,226,175,0.15); }
#custom-temp.temp-high     { color:#fab387; background:rgba(250,179,135,0.15); }
#custom-temp.temp-critical { color:#f38ba8; background:rgba(243,139,168,0.15); animation:temppulse 0.6s ease-in-out infinite alternate; }
@keyframes temppulse { from{background:rgba(243,139,168,0.10)} to{background:rgba(243,139,168,0.30)} }

/* ── Workspace Colors ────────────────────────────────────────────────────── */
#workspaces button          { color:#6c7086; background:transparent; border-bottom:2px solid transparent; }
#workspaces button.occupied { color:#cdd6f4; background:rgba(205,214,244,0.1); border-bottom:2px solid #89b4fa; }
#workspaces button.active   { color:#1e1e2e; background:#89b4fa; border-bottom:2px solid #89b4fa; font-weight:bold; }
#workspaces button.urgent   { color:#1e1e2e; background:#f38ba8; }
CSS
    log "Waybar CSS styles added."

    # Waybar module config snippet
    info "Add these to your waybar config modules-right:"
    info '  "custom/nvidia-gpu", "custom/fan", "custom/temp"'
    info ""
    info "And add these module definitions:"
    cat <<'WAYBARCFG'
    "custom/nvidia-gpu": {
        "exec": "~/.config/waybar/scripts/nvidia-gpu.sh",
        "return-type": "json", "interval": 3, "tooltip": true,
        "on-click": "kitty --title 'GPU Monitor' nvidia-smi dmon -s pucet"
    },
    "custom/fan": {
        "exec": "~/.config/waybar/scripts/fan-speed.sh",
        "return-type": "json", "interval": 3, "tooltip": true,
        "on-click": "kitty --title 'Fan Monitor' watch -n1 sensors"
    },
    "custom/temp": {
        "exec": "~/.config/waybar/scripts/temp-monitor.sh",
        "return-type": "json", "interval": 3, "tooltip": true,
        "on-click": "kitty --title 'Temp Monitor' watch -n1 sensors"
    }
WAYBARCFG

elif $do_waybar && [ "$DISTRO" != "arch" ]; then
    skip "Waybar modules (Arch only)"
fi

# =============================================================================
# MODULE 8 — Game Saves Symlinks
# =============================================================================
if $do_saves; then
    section "Module 8: Game Saves → Storage Drive"

    SAVES_BASE="$STORAGE_PATH/Saves"
    ## /home/ahmdhosni/.var/app/com.valvesoftware.Steam/.local/share/aspyr-media
    ## /media/ahmdhosni/Storage/Apps/Flatpak/app/com.valvesoftware.Steam/.local/share
    ## $FLATPAK_STORAGE/app/com.valvesoftware.Steam/.local/share/aspyr-media
    # CIV6_SOURCE="$HOME/.local/share/aspyr-media"
    CIV6_SOURCE="$FLATPAK_STORAGE/app/com.valvesoftware.Steam/.local/share/aspyr-media"
    CIV6_TARGET="$SAVES_BASE/civ6/aspyr"

    if [ ! -d "$STORAGE_PATH" ]; then
        warn "Storage drive not found at $STORAGE_PATH"
        warn "Mount the drive and re-run with option 8 to set up saves."
    else
        mkdir -p "$CIV6_SOURCE"
        mkdir -p "$CIV6_TARGET"
        mkdir -p "$SAVES_BASE/userdata"
        mkdir -p "$SAVES_BASE/screenshots"

        # aspyr-media (Civ6)
        if [ -L "$CIV6_SOURCE" ]; then
            warn "aspyr-media already symlinked — skipping."
        elif [ -d "$CIV6_SOURCE" ]; then
            cp -rn "$CIV6_SOURCE/." "$CIV6_TARGET/" 2>/dev/null || true
            rm -rf "$CIV6_SOURCE"
            ln -s "$CIV6_TARGET" "$CIV6_SOURCE"
            log "aspyr-media migrated and symlinked → $CIV6_TARGET"
        else
            ln -s "$CIV6_TARGET" "$CIV6_SOURCE"
            log "aspyr-media symlink created (pre-emptive) → $CIV6_TARGET"
        fi

        # Steam userdata
        # Since ~/.var is now symlinked to storage drive (shared Flatpak),
        # Steam userdata inside ~/.var/app/com.valvesoftware.Steam is
        # ALREADY on the storage drive — no separate symlink needed.
        # We only symlink saves that live OUTSIDE Flatpak (native Steam on Arch)
        if [ "$DISTRO" = "arch" ] && [ -d "$HOME/.local/share/Steam/userdata" ] && [ ! -L "$HOME/.local/share/Steam/userdata" ]; then
            STEAM_USERDATA="$HOME/.local/share/Steam/userdata"
            cp -rn "$STEAM_USERDATA/." "$SAVES_BASE/userdata/" 2>/dev/null || true
            rm -rf "$STEAM_USERDATA"
            ln -s "$SAVES_BASE/userdata" "$STEAM_USERDATA"
            log "Native Steam userdata symlinked → $SAVES_BASE/userdata"
        else
            info "Steam userdata is inside ~/.var (Flatpak) which is already on storage drive."
            info "No additional userdata symlink needed."
        fi

        # game-save-link helper
        mkdir -p "$HOME/.local/bin"
        cat >"$HOME/.local/bin/game-save-link" <<HELPERSCRIPT
#!/bin/bash
SAVES_DIR="$SAVES_BASE/per-game"
SRC="\$1"; NAME="\${2:-\$(basename "\$SRC")}"
[ -z "\$SRC" ] && echo "Usage: game-save-link <path> [name]" && exit 1
[ -L "\$SRC" ] && echo "Already a symlink." && exit 0
mkdir -p "\$SAVES_DIR"
cp -r "\$SRC" "\$HOME/game-save-bak-\$(date +%Y%m%d)-\$NAME"
cp -rn "\$SRC/." "\$SAVES_DIR/\$NAME/" 2>/dev/null || cp -r "\$SRC" "\$SAVES_DIR/\$NAME"
rm -rf "\$SRC"
ln -s "\$SAVES_DIR/\$NAME" "\$SRC"
echo "[✓] \$NAME saves symlinked to \$SAVES_DIR/\$NAME"
HELPERSCRIPT
        chmod +x "$HOME/.local/bin/game-save-link"
        log "game-save-link helper installed at ~/.local/bin/game-save-link"
    fi
fi

# =============================================================================
# Add ~/.local/bin to PATH
# =============================================================================
# SHELL_RC="$HOME/.bashrc"
# [[ "$SHELL" == *zsh* ]] && SHELL_RC="$HOME/.zshrc"
# if ! grep -q '\.local/bin' "$SHELL_RC" 2>/dev/null; then
#     echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$SHELL_RC"
#     log "Added ~/.local/bin to PATH in $SHELL_RC"
# fi

# =============================================================================
# DONE
# =============================================================================
banner "Setup Complete!"

echo -e "
${GREEN}All selected modules installed successfully.${NC}

${YELLOW}Key commands:${NC}
  nvidia-toggle status  → check GPU mode
  nvidia-toggle intel   → switch to Intel-only (reboot required)
  nvidia-toggle hybrid  → switch to Hybrid mode (reboot required)
  game-save-link <path> → symlink a game's save folder to storage drive

${YELLOW}For Arch — update command (keeps NVIDIA in sync with kernel):${NC}
  paru -Syyu

${YELLOW}Per-game Quadro activation in Steam:${NC}
  __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia %command%

${YELLOW}Reboot to apply all changes:${NC}
  sudo reboot
"

read -rp "Reboot now? [Y/n] " rb
rb=${rb:-Y}
[[ "$rb" =~ ^[Yy]$ ]] && sudo reboot || echo "Remember to reboot when ready."
