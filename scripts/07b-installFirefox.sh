#!/usr/bin/env bash
#============================================================#
#                    Firefox Install Script                  #
#                     For Debian-based distros               #
#============================================================#
# Installs Firefox from Mozilla's official repo with all
# steps showing in tmux right pane
#============================================================#

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"

# Start tmux if not already in it
start_tmux

# Cache sudo password
cache_sudo

#==================#
#   Main Setup     #
#==================#

show_title "Installing Firefox from Mozilla" "Latest version, not Firefox ESR"

echo -e "${CYAN}This will install Firefox from Mozilla's official repository${NC}"
echo -e "${CYAN}You'll receive updates directly from Mozilla, not Debian${NC}"
echo ""

# Total steps to show progress
TOTAL_PACKAGES=9
CURRENT_PACKAGE=0

#-------------------------
# Step 1: Clean old files
#-------------------------
CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))
echo ""
echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Cleaning up old Mozilla repository files${NC}"
echo -e "${YELLOW}Description: Remove any existing broken configuration${NC}"

CLEANUP_CMD='rm -f /etc/apt/sources.list.d/mozilla.list /etc/apt/preferences.d/mozilla && echo "✓ Old files removed"'

if tmux_run_command "$CLEANUP_CMD" 1 "true"; then
    echo -e "${GREEN}✓ Cleanup complete${NC}"
    sleep 1
else
    echo -e "${YELLOW}⚠ No old files to clean (this is fine)${NC}"
    sleep 1
fi

#-------------------------
# Step 2: Install wget
#-------------------------
if ! command -v wget >/dev/null 2>&1; then
    CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))
    install_package "wget" "Download tool for fetching Mozilla signing key"
fi

#-------------------------
# Step 3: Install gnupg
#-------------------------
if ! command -v gpg >/dev/null 2>&1; then
    CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))
    install_package "gnupg" "GPG tool for verifying Mozilla signing key"
fi

#===========================#
#   Step 4: Create Key Dir  #
#===========================#
CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))
echo ""
echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Creating APT keyrings directory${NC}"
echo -e "${YELLOW}Description: Directory for APT repository signing keys${NC}"

if tmux_run_command "install -d -m 0755 /etc/apt/keyrings" 1 "true"; then
    echo -e "${GREEN}✓ Keyrings directory created${NC}"
    sleep 1
else
    echo -e "${RED}✗ Failed to create keyrings directory${NC}"
    exit 1
fi

#=========================================#
#   Step 5: Download Mozilla APT Key      #
#=========================================#
CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))
echo ""
echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Downloading Mozilla signing key${NC}"
echo -e "${YELLOW}Description: Official key to verify Mozilla packages${NC}"
echo -e "${CYAN}Downloading from: packages.mozilla.org${NC}"

if tmux_run_command "wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O /etc/apt/keyrings/packages.mozilla.org.asc" 2 "true"; then
    echo -e "${GREEN}✓ Mozilla signing key downloaded${NC}"
    sleep 1
else
    echo -e "${RED}✗ Failed to download Mozilla signing key${NC}"
    exit 1
fi

#===============================#
#   Step 6: Verify Fingerprint  #
#===============================#
CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))
echo ""
echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Verifying key fingerprint${NC}"
echo -e "${YELLOW}Description: Ensuring key is authentic and not tampered${NC}"

EXPECTED_FP="35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3"

# Create verification script
cat >/tmp/verify_mozilla_key.sh <<'VERIFY_SCRIPT'
#!/bin/bash
EXPECTED_FP="35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3"
GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
chmod 0700 "$GNUPGHOME"

FP_OUTPUT=$(gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc 2>&1 || true)
FP="$(printf '%s\n' "$FP_OUTPUT" | awk '/[A-F0-9]{40}/ { gsub(/[^A-F0-9]/,"",$0); print toupper($0); exit }' || true)"

rm -rf "$GNUPGHOME"

if [ "$FP" = "$EXPECTED_FP" ]; then
    echo "✓ Fingerprint verified: $FP"
    exit 0
else
    echo "✗ Fingerprint mismatch!"
    echo "  Expected: $EXPECTED_FP"
    echo "  Got: $FP"
    exit 1
fi
VERIFY_SCRIPT

chmod +x /tmp/verify_mozilla_key.sh

if tmux_run_command "bash /tmp/verify_mozilla_key.sh" 2 "false"; then
    echo -e "${GREEN}✓ Key fingerprint verified successfully${NC}"
    echo -e "${CYAN}  Fingerprint: ${EXPECTED_FP}${NC}"
    sleep 1
else
    echo -e "${RED}✗ Key fingerprint verification failed${NC}"
    rm -f /tmp/verify_mozilla_key.sh
    exit 1
fi

rm -f /tmp/verify_mozilla_key.sh

#=========================================#
#   Step 7: Add Mozilla APT Repository    #
#=========================================#
CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))
echo ""
echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Adding Mozilla APT repository${NC}"
echo -e "${YELLOW}Description: Adding packages.mozilla.org to APT sources${NC}"

# FIXED: Create the repository file with proper syntax
# Using cat with heredoc to ensure proper formatting
ADD_REPO_CMD='cat > /etc/apt/sources.list.d/mozilla.list << "REPOEOF"
deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main
REPOEOF
echo "✓ Mozilla repository added"'

if tmux_run_command "$ADD_REPO_CMD" 1 "true"; then
    echo -e "${GREEN}✓ Mozilla APT repository configured${NC}"
    sleep 1
else
    echo -e "${RED}✗ Failed to add Mozilla repository${NC}"
    exit 1
fi

#===============================================#
#   Step 8: Configure APT Pinning (Priority)    #
#===============================================#
CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))
echo ""
echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Configuring APT pinning${NC}"
echo -e "${YELLOW}Description: Prioritize Mozilla packages over Debian packages${NC}"

# FIXED: Use heredoc for proper formatting
PIN_CMD='cat > /etc/apt/preferences.d/mozilla << "PINEOF"
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
PINEOF
echo "✓ APT pinning configured"'

if tmux_run_command "$PIN_CMD" 1 "true"; then
    echo -e "${GREEN}✓ APT pinning configured${NC}"
    echo -e "${CYAN}  Mozilla packages will be preferred over Debian${NC}"
    sleep 1
else
    echo -e "${RED}✗ Failed to configure APT pinning${NC}"
    exit 1
fi

#=========================================#
#   Step 9: Update APT Cache              #
#=========================================#
CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))
echo ""
echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Updating APT cache${NC}"
echo -e "${YELLOW}Description: Refreshing package lists including Mozilla repository${NC}"

if tmux_run_command "apt update" 2 "true"; then
    echo -e "${GREEN}✓ APT cache updated${NC}"
    sleep 1
else
    echo -e "${RED}✗ Failed to update APT cache${NC}"
    echo -e "${YELLOW}Checking repository file...${NC}"
    sudo cat /etc/apt/sources.list.d/mozilla.list
    exit 1
fi

#=========================================#
#   Step 10: Install Firefox              #
#=========================================#
CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))
echo ""
echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Installing Firefox from Mozilla${NC}"
echo -e "${YELLOW}Description: Latest Firefox (not ESR) with all recommended packages${NC}"
echo -e "${CYAN}This may take a few minutes...${NC}"

# Install Firefox using tmux_run_command for live output
sleep 1
if tmux_run_command "apt-get install -y firefox" 3 "true"; then
    echo -e "${GREEN}✓ Firefox installed successfully${NC}"

    # Show installed version
    if command -v firefox >/dev/null 2>&1; then
        VERSION=$(firefox --version 2>/dev/null | sed 's/Mozilla Firefox //' || echo "Unknown")
        echo -e "${CYAN}  Installed version: ${VERSION}${NC}"
    fi
    sleep 1
else
    echo -e "${RED}✗ Failed to install Firefox${NC}"
    exit 1
fi

#=========================================#
#   Installation Complete                 #
#=========================================#
echo ""
show_title "Firefox Installation Complete!" "Latest Firefox is now installed from Mozilla"

echo -e "${GREEN}${BOLD}Summary:${NC}"
echo -e "${GREEN}  ✓ Mozilla APT repository added${NC}"
echo -e "${GREEN}  ✓ APT pinning configured (priority: 1000)${NC}"
echo -e "${GREEN}  ✓ Firefox installed from Mozilla (not ESR)${NC}"
echo -e "${GREEN}  ✓ Future updates will come from Mozilla${NC}"
echo ""
echo -e "${CYAN}You can now launch Firefox from your applications menu${NC}"
echo -e "${CYAN}Run 'firefox --version' to verify the installation${NC}"
echo ""

exit 0
