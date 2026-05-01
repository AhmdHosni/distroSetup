#!/bin/zsh
# =============================================================================
# NVIDIA Pascal (Quadro P3200) + HDMI Setup Script
# Target: Arch Linux (linux-zen) + GNOME 49 minimal install + zsh
# GPU:    NVIDIA Quadro P3200 (Pascal/GP104) - Dell Precision 7350
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }
section() {
    echo -e "\n${BLUE}══════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
}

[ "$EUID" -eq 0 ] && error "Do not run as root. Run as your normal user."

# =============================================================================
# STEP 0 — Preflight checks
# =============================================================================
section "Preflight Checks"

KERNEL=$(uname -r)
if [[ "$KERNEL" != *zen* ]]; then
    warn "Kernel is '$KERNEL' — this script is tuned for linux-zen."
    read -rq "confirm?Continue anyway? [y/N] " || exit 1
    echo
fi
log "Kernel: $KERNEL"

# Check for paru
if ! command -v paru &>/dev/null; then
    warn "paru not found. Installing paru AUR helper..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm)
    rm -rf /tmp/paru
fi
log "AUR helper (paru) is available."

# =============================================================================
# STEP 1 — Blacklist nouveau
# =============================================================================
section "Step 1: Blacklisting nouveau"

if [ ! -f /etc/modprobe.d/blacklist-nouveau.conf ]; then
    printf "blacklist nouveau\noptions nouveau modeset=0\n" | \
        sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null
    log "nouveau blacklisted."
else
    warn "nouveau blacklist already exists, skipping."
fi

# =============================================================================
# STEP 2 — Install kernel headers + Intel driver
# =============================================================================
section "Step 2: Installing kernel headers and Intel driver"

sudo pacman -S --needed --noconfirm \
    linux-zen-headers \
    mesa \
    vulkan-intel \
    intel-media-driver \
    libva-intel-driver

log "Kernel headers and Intel driver installed."

# =============================================================================
# STEP 3 — Install legacy NVIDIA Pascal driver (580xx) from AUR
# =============================================================================
section "Step 3: Installing NVIDIA Pascal legacy driver (nvidia-580xx-dkms)"

# Remove conflicting open driver if present
if pacman -Q nvidia-open-dkms &>/dev/null; then
    warn "Removing conflicting nvidia-open-dkms..."
    sudo pacman -Rdd --noconfirm nvidia-open-dkms
fi

paru -S --needed --noconfirm nvidia-580xx-dkms nvidia-580xx-utils

log "NVIDIA Pascal driver installed."

# =============================================================================
# STEP 4 — Configure mkinitcpio
# =============================================================================
section "Step 4: Configuring initramfs (mkinitcpio)"

MKINIT="/etc/mkinitcpio.conf"

# Add nvidia modules
if grep -q "^MODULES=()" "$MKINIT"; then
    sudo sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$MKINIT"
    log "NVIDIA modules added to MODULES=()."
elif grep -q "^MODULES=(" "$MKINIT" && ! grep -q "nvidia" "$MKINIT"; then
    sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$MKINIT"
    log "NVIDIA modules appended to existing MODULES=()."
else
    warn "MODULES already contains nvidia entries — skipping."
fi

# Remove kms hook — conflicts with nvidia early modesetting
if grep -q " kms" "$MKINIT"; then
    sudo sed -i 's/ kms//' "$MKINIT"
    warn "Removed 'kms' from HOOKS (conflicts with NVIDIA early modesetting)."
fi

log "Rebuilding initramfs..."
sudo mkinitcpio -P

# =============================================================================
# STEP 5 — GRUB kernel parameter
# =============================================================================
section "Step 5: Adding nvidia_drm.modeset=1 to GRUB"

GRUB_CFG="/etc/default/grub"

if ! grep -q "nvidia_drm.modeset=1" "$GRUB_CFG"; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' "$GRUB_CFG"
    log "nvidia_drm.modeset=1 added to GRUB."
else
    warn "nvidia_drm.modeset=1 already in GRUB config, skipping."
fi

log "Regenerating GRUB config..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

# =============================================================================
# STEP 6 — GNOME + GDM Wayland NVIDIA environment variables
# =============================================================================
section "Step 6: Configuring NVIDIA env vars for GNOME/GDM"

# System-wide environment for Wayland session
ENV_DIR="/etc/environment.d"
ENV_FILE="$ENV_DIR/nvidia-gnome.conf"

sudo mkdir -p "$ENV_DIR"

if [ ! -f "$ENV_FILE" ]; then
    sudo tee "$ENV_FILE" > /dev/null << 'EOF'
# NVIDIA Wayland environment variables for GNOME
LIBVA_DRIVER_NAME=nvidia
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
__NV_PRIME_RENDER_OFFLOAD=1
__VK_LAYER_NV_optimus=NVIDIA_only
NVD_BACKEND=direct
EOF
    log "NVIDIA env vars written to $ENV_FILE."
else
    warn "$ENV_FILE already exists, skipping."
fi

# Also set for GDM (display manager) so the login screen works
GDM_ENV="/etc/gdm/custom.conf"
if [ -f "$GDM_ENV" ]; then
    if ! grep -q "WaylandEnable" "$GDM_ENV"; then
        sudo sed -i '/^\[daemon\]/a WaylandEnable=true' "$GDM_ENV"
        log "Wayland enabled in GDM config."
    else
        warn "GDM Wayland config already set, skipping."
    fi
else
    warn "GDM config not found at $GDM_ENV — GDM may not be installed yet."
fi

# =============================================================================
# STEP 7 — Install GNOME essentials if missing
# =============================================================================
section "Step 7: Installing GNOME essentials"

sudo pacman -S --needed --noconfirm \
    gnome \
    gnome-tweaks \
    gnome-shell-extensions \
    gdm \
    xdg-user-dirs \
    xdg-desktop-portal \
    xdg-desktop-portal-gnome \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    wireplumber

log "GNOME packages installed."

# =============================================================================
# STEP 8 — Enable GDM (display manager)
# =============================================================================
section "Step 8: Enabling GDM display manager"

if ! systemctl is-enabled gdm &>/dev/null; then
    sudo systemctl enable gdm
    log "GDM enabled."
else
    warn "GDM already enabled, skipping."
fi

# =============================================================================
# STEP 9 — Per-app NVIDIA GPU forcing via environment.d
# =============================================================================
section "Step 9: Per-app NVIDIA GPU config"

USER_ENV_DIR="$HOME/.config/environment.d"
mkdir -p "$USER_ENV_DIR"

USER_ENV_FILE="$USER_ENV_DIR/nvidia-prime.conf"

if [ ! -f "$USER_ENV_FILE" ]; then
    cat > "$USER_ENV_FILE" << 'EOF'
# Force NVIDIA GPU for user applications (PRIME render offload)
# This makes your Quadro P3200 handle rendering for all user apps
# while Intel iGPU handles the display output
__NV_PRIME_RENDER_OFFLOAD=1
__NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
__GLX_VENDOR_LIBRARY_NAME=nvidia
__VK_LAYER_NV_optimus=NVIDIA_only
EOF
    log "Per-app NVIDIA GPU config written to $USER_ENV_FILE."
else
    warn "Per-app NVIDIA config already exists, skipping."
fi

# Helper script to launch any app on NVIDIA GPU explicitly
PRIME_SCRIPT="$HOME/.local/bin/prime-run"
mkdir -p "$HOME/.local/bin"

if [ ! -f "$PRIME_SCRIPT" ]; then
    cat > "$PRIME_SCRIPT" << 'EOF'
#!/bin/zsh
# Run any app on the NVIDIA GPU
# Usage: prime-run <application>
# Example: prime-run steam
__NV_PRIME_RENDER_OFFLOAD=1 \
__NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
__VK_LAYER_NV_optimus=NVIDIA_only \
exec "$@"
EOF
    chmod +x "$PRIME_SCRIPT"
    log "prime-run helper script created at $PRIME_SCRIPT."
fi

# Add ~/.local/bin to PATH in .zshrc if not already there
if ! grep -q '\.local/bin' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    log "Added ~/.local/bin to PATH in .zshrc."
fi

# =============================================================================
# STEP 10 — HDMI note (GNOME handles this automatically)
# =============================================================================
section "Step 10: HDMI / External Monitor"

echo -e "${GREEN}[+]${NC} GNOME handles external monitors automatically via Settings."
echo -e "    Once booted into GNOME, go to:"
echo -e "    ${YELLOW}Settings → Displays${NC}"
echo -e "    Your HDMI monitor will appear there to configure resolution,"
echo -e "    position (extend/mirror), and refresh rate."

# =============================================================================
# DONE
# =============================================================================
section "Setup Complete!"

echo -e "
${GREEN}Everything is configured. Here's what was done:${NC}

  ✅ nouveau blacklisted
  ✅ linux-zen-headers installed
  ✅ Intel driver (mesa, vulkan-intel, intel-media-driver) installed
  ✅ nvidia-580xx-dkms (Pascal legacy driver) installed from AUR
  ✅ NVIDIA modules added to mkinitcpio
  ✅ initramfs rebuilt
  ✅ nvidia_drm.modeset=1 added to GRUB
  ✅ GRUB config regenerated
  ✅ NVIDIA env vars written to /etc/environment.d/nvidia-gnome.conf
  ✅ Wayland enabled in GDM
  ✅ GNOME + GDM + PipeWire installed
  ✅ GDM enabled (systemctl)
  ✅ Per-app NVIDIA config written to ~/.config/environment.d/
  ✅ prime-run helper script created at ~/.local/bin/prime-run

${YELLOW}Please reboot now:${NC}
  sudo reboot

${YELLOW}After reboot:${NC}
  • GNOME will start via GDM
  • HDMI monitor → Settings → Displays (auto-detected)
  • To run any app on NVIDIA GPU:
      prime-run <app>
      prime-run steam
      prime-run firefox
  • To verify GPU is working:
      nvidia-smi

${YELLOW}GNOME Display Settings for HDMI:${NC}
  Settings → Displays → choose Mirror or Extended
"
