#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          lib_functions.sh
# Location:      scripts/libs/lib_functions.sh
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Description:   Shared functions library.
#                 Each script in scripts/ sources it via a relative path:
#                     THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#                     source "$THIS_DIR/libs/lib_functions.sh"
#--------------------------------------------------------------------------------

###################
# Color definitions
###################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

#####################
# Detect Package Manager (runs once on source)
#####################

if command -v pacman &>/dev/null; then
    DISTRO="arch"
    PM_INSTALL="pacman -S --needed --noconfirm"
elif command -v apt-get &>/dev/null; then
    DISTRO="debian"
    PM_INSTALL="apt-get install -y"
else
    echo -e "${RED}${BOLD}[lib_functions] No supported package manager found.${NC}"
    return 1 # return instead of exit so we don't kill the calling script
fi

#####################
# Progress Tracking  (shared state across all scripts in one run)
#####################

CURRENT_PACKAGE=0
TOTAL_PACKAGES=0

#####################
# Sudo — password-in-variable approach
#####################

# Wrapper function that shadows the "sudo" binary.
# Every call to "sudo ..." anywhere in any script that sourced this lib
# hits this function instead of the binary.  It pipes the cached password
# into "command sudo -S" (read password from stdin).
# "command sudo" bypasses the function itself — no recursion.
sudo() {
    echo "$SUDO_PASS" | command sudo -S "$@"
}

# Ask for the password once, validate it, export it.
# Every child process (including tmux split panes) inherits it via the
# environment.  No tty, no credential cache, no -v, no -n needed.
# Call this AFTER start_tmux (exec replaces the shell).
cache_sudo() {
    # If already set and valid (e.g. inherited after exec), skip the prompt.
    if [ -n "$SUDO_PASS" ]; then
        if echo "$SUDO_PASS" | command sudo -S true 2>/dev/null; then
            return 0
        fi
    fi

    echo -e "${YELLOW}${BOLD}Please enter your password:${NC}"
    read -rsp "Password: " SUDO_PASS
    echo "" # newline after the hidden input

    # Validate — -k flushes any stale kernel cache so -S is authoritative
    if ! echo "$SUDO_PASS" | command sudo -S -k true 2>/dev/null; then
        echo -e "${RED}${BOLD}✗ Incorrect password. Exiting.${NC}"
        exit 1
    fi

    export SUDO_PASS
    echo -e "${GREEN}✓ Password accepted${NC}"
}

################
##### Tmux Setup
################

# Temp file used as a status signal between the left (main) and right (install) panes.
STATUS_FILE=$(mktemp)

# Ensure Tmux is Installed
ensure_tmux() {
    if ! command -v tmux &>/dev/null; then
        echo -e "${YELLOW}${BOLD}Tmux not found, installing...${NC}"
        sudo ${PM_INSTALL} tmux &>/dev/null

        if command -v tmux &>/dev/null; then
            echo -e "${GREEN}✓ Tmux installed${NC}"

            # Copy custom tmux configuration if available
            local THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            local CONFIGS_DIR="$THIS_DIR/../configs/tmux"

            if [ -d "$CONFIGS_DIR" ] && [ -f "$CONFIGS_DIR/tmux.conf" ]; then
                echo -e "${YELLOW}${BOLD}Copying custom tmux configuration...${NC}"
                mkdir -p "$HOME/.config/tmux"
                cp "$CONFIGS_DIR/tmux.conf" "$HOME/.config/tmux/tmux.conf"
                #ln -sf "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"
                echo -e "${GREEN}✓ Tmux config copied${NC}"

                if [ -d "$CONFIGS_DIR/plugins" ]; then
                    cp -r "$CONFIGS_DIR/plugins" "$HOME/.config/tmux/"
                    echo -e "${GREEN}✓ Tmux plugins copied${NC}"
                fi
            fi
        else
            echo -e "${RED}✗ Failed to install tmux${NC}"
            return 1
        fi
    fi
}

# Clean Stale Tmux Session
clean_stale_tmux() {
    # Check if TMUX variable is set but session doesn't exist
    if [ -n "$TMUX" ]; then
        if ! tmux list-sessions &>/dev/null 2>&1; then
            # Session is dead but TMUX variable still set - clean it up
            echo -e "${YELLOW}⚠ Cleaning up stale tmux session...${NC}"
            unset TMUX
            unset TMUX_PANE
            rm -f /tmp/tmux-*/default 2>/dev/null
        fi
    fi
}

# Start Tmux Session
start_tmux() {
    ensure_tmux || return 1

    # Skip tmux creation if running under runScript.sh
    if [ "$RUNNING_FROM_SCRIPT_RUNNER" = "true" ]; then
        # But still clean up stale sessions
        clean_stale_tmux
        return 0
    fi

    # Clean stale sessions first
    clean_stale_tmux

    if [ -z "$TMUX" ]; then
        # Not in tmux - kill old session if it exists and create new one
        tmux kill-session -t "installer" 2>/dev/null

        # Clean up any stale socket files
        rm -f /tmp/tmux-*/default 2>/dev/null

        # Create new session
        exec tmux new-session -s "installer" -- "$0" "$@"
    fi
    # Already in valid tmux session - do nothing
}

# Run Command in Tmux Split Pane
tmux_run_command() {
    local command="$1"
    local sleep_duration="${2:-1}"
    local use_sudo="${3:-true}"

    # CRITICAL FIX: Clean stale tmux sessions before trying to use tmux
    clean_stale_tmux

    # CRITICAL FIX: Ensure we're actually in a tmux session
    if [ -z "$TMUX" ]; then
        echo -e "${RED}✗ Error: Not in tmux session. Call start_tmux first.${NC}"
        return 1
    fi

    # Verify tmux session is actually valid
    if ! tmux list-sessions &>/dev/null 2>&1; then
        echo -e "${RED}✗ Error: Tmux session is not valid. Please restart script.${NC}"
        return 1
    fi

    # Clear status file
    >"$STATUS_FILE"

    if [ "$use_sudo" = "true" ]; then
        export SUDO_PASS

        if [ "$DISTRO" = "debian" ]; then
            tmux split-window -h \
                "bash -c 'echo \"\$SUDO_PASS\" | command sudo -S sh -c \"${command} 2>&1\"; RC=\$?; echo \$RC > ${STATUS_FILE}; sleep ${sleep_duration}; exit'"
        else
            tmux split-window -h \
                "bash -c 'echo \"\$SUDO_PASS\" | command sudo -S sh -c \"${command} 2>&1\"; RC=\$?; echo \$RC > ${STATUS_FILE}; sleep ${sleep_duration}; exit'"
        fi
    else
        if [ "$DISTRO" = "debian" ]; then
            tmux split-window -h \
                "bash -c '${command}; echo \$? > ${STATUS_FILE}; sleep ${sleep_duration}; exit'"
        else
            tmux split-window -h \
                "bash -c 'sh -c \"${command} 2>&1\"; RC=\$?; echo \$RC > ${STATUS_FILE}; sleep ${sleep_duration}; exit'"
        fi
    fi

    # Poll until the right pane writes the exit code
    while [ ! -s "$STATUS_FILE" ]; do
        sleep 1
    done

    local exit_code
    exit_code=$(cat "$STATUS_FILE")

    tmux select-pane -t 0 2>/dev/null || true

    return "$exit_code"
}

#####################
# Enhanced show_title with Optional Subtitle
#####################

# Prints a styled section title with optional subtitle
# Usage:  show_title "Main Title" ["Optional Subtitle"]
show_title() {
    local title="$1"
    local subtitle="$2" # Optional subtitle

    echo ""
    echo ""
    echo -e "${CYAN}${BOLD}========================================${NC}"
    echo -e "${CYAN}${BOLD}  ${title}${NC}"
    [ -n "$subtitle" ] && echo -e "${CYAN}  ${subtitle}${NC}"
    echo -e "${CYAN}${BOLD}========================================${NC}"
}

#####################
# System Update quiet (no tmux)
#####################

# Runs a full system update for the detected distro.
# Usage:  system_update
system_update_quiet() {
    show_title "System Update"
    echo -e "${YELLOW}${BOLD}Updating system packages...${NC}"

    if [ "$DISTRO" = "debian" ]; then
        if sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y &>/dev/null; then
            echo -e "${GREEN}✓ System update completed successfully${NC}"
        else
            echo -e "${RED}✗ System update failed${NC}"
            return 1
        fi
    else
        if sudo pacman -Syyu --noconfirm &>/dev/null; then
            echo -e "${GREEN}✓ System update completed successfully${NC}"
        else
            echo -e "${RED}✗ System update failed${NC}"
            return 1
        fi
    fi
}

################
# System Update (with tmux panels)
#####################

# Runs a full system update for the detected distro.
# Usage:  system_update
system_update() {
    show_title "System Update"
    echo -e "${YELLOW}${BOLD}Updating system packages...${NC}"

    # Build command based on distro
    local update_command
    if [ "$DISTRO" = "debian" ]; then
        update_command="apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y"
        echo -e "${CYAN}Running: apt-get update && apt-get upgrade && apt-get dist-upgrade${NC}"
    else
        update_command="pacman -Syyu --noconfirm"
        echo -e "${CYAN}Running: pacman -Syyu${NC}"
    fi

    echo -e "${CYAN}This may take several minutes...${NC}"
    echo -e "${CYAN}Watch the right pane for progress...${NC}"
    echo ""

    # --- Update via tmux_run_command helper (2 second sleep, sudo=true) ---
    if tmux_run_command "${update_command}" 2 "true"; then
        echo ""
        echo -e "${GREEN}✓ System update completed successfully${NC}"
        sleep 1
        return 0
    else
        echo ""
        echo -e "${RED}✗ System update failed${NC}"
        sleep 1
        return 1
    fi
}

#####################
# Install Package (REFACTORED)
#####################

# Installs a package and shows the live output in a tmux right pane.
# Usage:  install_package "package-name" "Optional description"
install_package() {
    local package_name="$1"
    local description="$2"

    CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))

    echo ""
    echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Installing: ${package_name}${NC}"
    [ -n "$description" ] && echo -e "${YELLOW}Description: ${description}${NC}"

    # --- Already-installed check ---
    if [ "$DISTRO" = "debian" ]; then
        if dpkg -s ${package_name} &>/dev/null; then
            echo -e "${BLUE}⊙ Already installed: ${package_name}${NC}"
            return 0
        fi
    else
        if pacman -Q ${package_name} &>/dev/null; then
            echo -e "${BLUE}⊙ Already installed: ${package_name}${NC}"
            return 0
        fi
    fi

    # --- Install via tmux_run_command helper (1 second sleep, sudo=true) ---
    echo -e "${CYAN}Installing package, please wait (right pane)...${NC}"

    if tmux_run_command "${PM_INSTALL} ${package_name}" 1 "true"; then
        echo -e "${GREEN}✓ Successfully installed: ${package_name}${NC}"
        sleep 1
        return 0
    else
        echo -e "${RED}✗ Failed to install: ${package_name}${NC}"
        sleep 1
        return 1
    fi
}

#####################
# Install Package with Recommends
#####################

# Install package WITH recommended packages (Debian only)
# Usage:  install_package_recommends "package-name" "Optional description"
install_package_no_recommendations() {
    local package_name="$1"
    local description="$2"
    local old_pm_install="$PM_INSTALL"

    if [ "$DISTRO" = "debian" ]; then
        PM_INSTALL="apt-get install -y --no-install-recommends"
    fi

    CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))

    echo ""
    if [ "$DISTRO" = "debian" ]; then
        echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Installing: ${package_name} without any recommended packages${NC}"
    else
        echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Installing: ${package_name}${NC}"
    fi

    [ -n "$description" ] && echo -e "${YELLOW}Description: ${description}${NC}"

    # --- Already-installed check ---
    if [ "$DISTRO" = "debian" ]; then
        if dpkg -s ${package_name} &>/dev/null; then
            echo -e "${BLUE}⊙ Already installed: ${package_name}${NC}"
            PM_INSTALL="$old_pm_install"
            return 0
        fi
    else
        if pacman -Q ${package_name} &>/dev/null; then
            echo -e "${BLUE}⊙ Already installed: ${package_name}${NC}"
            return 0
        fi
    fi

    # --- Install via tmux_run_command helper ---
    echo -e "${CYAN}Installing package, please wait (right pane)...${NC}"

    if tmux_run_command "${PM_INSTALL} ${package_name}" 1 "true"; then
        echo -e "${GREEN}✓ Successfully installed: ${package_name}${NC}"
        PM_INSTALL="$old_pm_install"
        sleep 1
        return 0
    else
        echo -e "${RED}✗ Failed to install: ${package_name}${NC}"
        PM_INSTALL="$old_pm_install"
        sleep 1
        return 1
    fi
}

#####################
# Setup Rust Toolchain (with tmux split)
#####################

# Sets up Rust toolchain using rustup with live output in tmux pane
# Usage:  setup_rust_toolchain [toolchain]
# Default toolchain: stable
setup_rust_toolchain() {
    local toolchain="${1:-stable}"

    echo ""
    echo -e "${YELLOW}${BOLD}Setting up Rust toolchain: ${toolchain}${NC}"

    # Check if rustup is available
    if ! command -v rustup &>/dev/null; then
        echo -e "${RED}✗ rustup is not installed. Please install rustup first.${NC}"
        return 1
    fi

    # Check if already configured
    if rustup show active-toolchain 2>/dev/null | grep -q "$toolchain"; then
        echo -e "${BLUE}⊙ Rust toolchain already configured: ${toolchain}${NC}"
        return 0
    fi

    # --- Tmux split setup ---
    >"$STATUS_FILE"

    tmux split-window -h \
        "bash -c 'rustup default ${toolchain}; echo \$? > ${STATUS_FILE}; sleep 1; exit'"

    echo -e "${CYAN}Setting up Rust toolchain, please wait (right pane)...${NC}"

    # Poll until the right pane writes the exit code
    while [ ! -s "$STATUS_FILE" ]; do
        sleep 0.5
    done

    local exit_code
    exit_code=$(cat "$STATUS_FILE")

    # Ensure focus returns to the main (left) pane
    tmux select-pane -t 0 2>/dev/null || true

    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}✓ Rust toolchain configured successfully: ${toolchain}${NC}"
        # Show current toolchain info
        if command -v rustc &>/dev/null; then
            local rust_version
            rust_version=$(rustc --version 2>/dev/null | cut -d' ' -f2)
            echo -e "${CYAN}  → Rust version: ${rust_version}${NC}"
        fi
        sleep 1
        return 0
    else
        echo -e "${RED}✗ Failed to setup Rust toolchain${NC}"
        sleep 1
        return 1
    fi
}

#####################
# Install Cargo Package (with tmux split)
#####################

# Installs a cargo package with live output in tmux right pane
# Usage:  cargo_install_package "package-name" "Optional description" [--features "feature1,feature2"]
cargo_install_package() {
    local package_name="$1"
    local description="$2"
    shift 2
    local extra_args="$*"

    CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))

    echo ""
    echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Installing cargo package: ${package_name}${NC}"
    if [ -n "$description" ]; then
        echo -e "${YELLOW}Description: ${description}${NC}"
    fi
    [ -n "$extra_args" ] && echo -e "${YELLOW}Extra args: ${extra_args}${NC}"

    # Check if cargo is available
    if ! command -v cargo &>/dev/null; then
        echo -e "${RED}✗ cargo is not installed. Please install Rust first.${NC}"
        return 1
    fi

    # --- Already-installed check ---
    if cargo install --list 2>/dev/null | grep -q "^${package_name} "; then
        echo -e "${BLUE}⊙ Already installed: ${package_name}${NC}"
        # Show version if available
        local version
        version=$(cargo install --list 2>/dev/null | grep "^${package_name} " | awk '{print $2}' | tr -d 'v:()')
        [ -n "$version" ] && echo -e "${CYAN}  → Version: ${version}${NC}"
        return 0
    fi

    # --- Tmux split install ---
    >"$STATUS_FILE"

    echo -e "${CYAN}This may take several minutes as it compiles from source...${NC}"

    # Build the install command with filtering
    local install_cmd="cargo install ${package_name} ${extra_args} 2>&1 | while IFS= read -r line; do"
    install_cmd+=" if echo \"\$line\" | grep -qE 'Compiling|Finished|Installing|Downloaded|Updating'; then"
    install_cmd+=" echo \"\$line\"; fi; done; echo \${PIPESTATUS[0]} > ${STATUS_FILE}"

    tmux split-window -h "bash -c '${install_cmd}; sleep 1; exit'"

    echo -e "${CYAN}Installing package, please wait (right pane)...${NC}"

    # Poll until the right pane writes the exit code
    while [ ! -s "$STATUS_FILE" ]; do
        sleep 0.5
    done

    local exit_code
    exit_code=$(cat "$STATUS_FILE")

    # Ensure focus returns to the main (left) pane
    tmux select-pane -t 0 2>/dev/null || true

    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully installed: ${package_name}${NC}"
        # Show installed version
        local version
        version=$(cargo install --list 2>/dev/null | grep "^${package_name} " | awk '{print $2}' | tr -d 'v:()')
        [ -n "$version" ] && echo -e "${CYAN}  → Version: ${version}${NC}"
        sleep 1
        return 0
    else
        echo -e "${RED}✗ Failed to install: ${package_name}${NC}"
        sleep 1
        return 1
    fi
}

#####################
# Install NPM Package (with tmux split)
#####################

# Installs a global npm package with live output in tmux right pane
# Usage:  npm_install_package "package-name" "Optional description"
npm_install_package() {
    local package_name="$1"
    local description="$2"

    CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))

    echo ""
    echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Installing npm package: ${package_name}${NC}"
    if [ -n "$description" ]; then
        echo -e "${YELLOW}Description: ${description}${NC}"
    fi

    # Check if npm is available
    if ! command -v npm &>/dev/null; then
        echo -e "${RED}✗ npm is not installed. Please install Node.js first.${NC}"
        return 1
    fi

    # --- Already-installed check ---
    if npm list -g --depth=0 2>/dev/null | grep -q " ${package_name}@"; then
        echo -e "${BLUE}⊙ Already installed: ${package_name}${NC}"
        # Show version
        local version
        version=$(npm list -g --depth=0 2>/dev/null | grep " ${package_name}@" | sed 's/.*@//' | awk '{print $1}')
        [ -n "$version" ] && echo -e "${CYAN}  → Version: ${version}${NC}"
        return 0
    fi

    # --- Tmux split install ---
    >"$STATUS_FILE"

    tmux split-window -h \
        "bash -c 'npm install -g ${package_name}; echo \$? > ${STATUS_FILE}; sleep 1; exit'"

    echo -e "${CYAN}Installing package, please wait (right pane)...${NC}"

    # Poll until the right pane writes the exit code
    while [ ! -s "$STATUS_FILE" ]; do
        sleep 0.5
    done

    local exit_code
    exit_code=$(cat "$STATUS_FILE")

    # Ensure focus returns to the main (left) pane
    tmux select-pane -t 0 2>/dev/null || true

    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully installed: ${package_name}${NC}"
        # Show version
        local version
        version=$(npm list -g --depth=0 2>/dev/null | grep " ${package_name}@" | sed 's/.*@//' | awk '{print $1}')
        [ -n "$version" ] && echo -e "${CYAN}  → Version: ${version}${NC}"
        sleep 1
        return 0
    else
        echo -e "${RED}✗ Failed to install: ${package_name}${NC}"
        sleep 1
        return 1
    fi
}

#####################
# Rustup Component Add (with tmux split)
#####################

# Adds a rustup component with live output in tmux pane
# Usage:  rustup_add_component "component-name" "Optional description"
# Examples: rust-src, rust-analyzer, clippy, rustfmt
rustup_add_component() {
    local component_name="$1"
    local description="$2"

    echo ""
    echo -e "${YELLOW}${BOLD}Adding rustup component: ${component_name}${NC}"
    if [ -n "$description" ]; then
        echo -e "${YELLOW}Description: ${description}${NC}"
    fi

    # Check if rustup is available
    if ! command -v rustup &>/dev/null; then
        echo -e "${RED}✗ rustup is not installed. Please install rustup first.${NC}"
        return 1
    fi

    # Check if component is already installed
    if rustup component list --installed 2>/dev/null | grep -q "^${component_name}"; then
        echo -e "${BLUE}⊙ Component already installed: ${component_name}${NC}"
        return 0
    fi

    # --- Tmux split install ---
    >"$STATUS_FILE"

    tmux split-window -h \
        "bash -c 'rustup component add ${component_name}; echo \$? > ${STATUS_FILE}; sleep 1; exit'"

    echo -e "${CYAN}Adding component, please wait (right pane)...${NC}"

    # Poll until the right pane writes the exit code
    while [ ! -s "$STATUS_FILE" ]; do
        sleep 0.5
    done

    local exit_code
    exit_code=$(cat "$STATUS_FILE")

    # Ensure focus returns to the main (left) pane
    tmux select-pane -t 0 2>/dev/null || true

    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}✓ Component added successfully: ${component_name}${NC}"
        sleep 1
        return 0
    else
        echo -e "${RED}✗ Failed to add component: ${component_name}${NC}"
        sleep 1
        return 1
    fi
}

#####################
# Copy File
#####################

# Copies a single file into a destination folder.
# Usage:  copy_file "/source/file.txt" "/dest/folder" "Description" [sudo]
# 4th arg: "sudo" to force sudo, omit or "auto" for automatic
copy_file() {
    local source_file="$1"
    local dest_folder="$2"
    local description="$3"
    local use_sudo="${4:-auto}"

    echo ""
    echo -e "${YELLOW}${BOLD}Copying file: $(basename "$source_file")${NC}"
    [ -n "$description" ] && echo -e "${YELLOW}${BOLD}Description: ${description}${NC}"
    echo -e "${YELLOW}From: ${source_file}${NC}"
    echo -e "${YELLOW}To:   ${dest_folder}${NC}"

    if [ ! -f "$source_file" ]; then
        echo -e "${RED}✗ Source file does not exist: ${source_file}${NC}"
        return 1
    fi

    # Create destination folder if needed
    if [ ! -d "$dest_folder" ]; then
        echo -e "${CYAN}Creating destination folder...${NC}"
        if [ "$use_sudo" = "sudo" ]; then
            sudo mkdir -p "$dest_folder" 2>/dev/null || {
                echo -e "${RED}✗ Failed to create destination folder${NC}"
                return 1
            }
        else
            mkdir -p "$dest_folder" 2>/dev/null || sudo mkdir -p "$dest_folder" 2>/dev/null || {
                echo -e "${RED}✗ Failed to create destination folder${NC}"
                return 1
            }
        fi
        echo -e "${GREEN}✓ Destination folder created${NC}"
    fi

    # Copy
    echo -e "${CYAN}Copying file...${NC}"
    if [ "$use_sudo" = "sudo" ]; then
        if sudo cp "$source_file" "$dest_folder/" 2>/dev/null; then
            echo -e "${GREEN}✓ File copied successfully (with sudo)${NC}"
            return 0
        fi
    else
        if cp "$source_file" "$dest_folder/" 2>/dev/null; then
            echo -e "${GREEN}✓ File copied successfully${NC}"
            return 0
        elif sudo cp "$source_file" "$dest_folder/" 2>/dev/null; then
            echo -e "${GREEN}✓ File copied successfully (with sudo)${NC}"
            return 0
        fi
    fi

    echo -e "${RED}✗ Failed to copy file${NC}"
    return 1
}

#####################
# Copy Folder
#####################

# Copies an entire folder recursively to a destination.
# Usage:  copy_folder "/source/folder" "/dest/folder" "Description" [sudo]
# 4th arg: "sudo" to force sudo, omit or "auto" for automatic
copy_folder() {
    local source_folder="$1"
    local dest_folder="$2"
    local description="$3"
    local use_sudo="${4:-auto}"

    echo ""
    echo -e "${YELLOW}${BOLD}Copying folder: $(basename "$source_folder")${NC}"
    [ -n "$description" ] && echo -e "${YELLOW}${BOLD}Description: ${description}${NC}"
    echo -e "${YELLOW}From: ${source_folder}${NC}"
    echo -e "${YELLOW}To:   ${dest_folder}${NC}"

    if [ ! -d "$source_folder" ]; then
        echo -e "${RED}✗ Source folder does not exist: ${source_folder}${NC}"
        return 1
    fi

    # Create parent destination if needed
    local parent_dest="$(dirname "$dest_folder")"
    if [ ! -d "$parent_dest" ]; then
        echo -e "${CYAN}Creating parent destination folder...${NC}"
        if [ "$use_sudo" = "sudo" ]; then
            sudo mkdir -p "$parent_dest" 2>/dev/null || {
                echo -e "${RED}✗ Failed to create parent destination folder${NC}"
                return 1
            }
        else
            mkdir -p "$parent_dest" 2>/dev/null || sudo mkdir -p "$parent_dest" 2>/dev/null || {
                echo -e "${RED}✗ Failed to create parent destination folder${NC}"
                return 1
            }
        fi
        echo -e "${GREEN}✓ Parent destination folder created${NC}"
    fi

    # Copy
    echo -e "${CYAN}Copying folder contents...${NC}"
    if [ "$use_sudo" = "sudo" ]; then
        if sudo cp -r "$source_folder" "$dest_folder" 2>/dev/null; then
            echo -e "${GREEN}✓ Folder copied successfully (with sudo)${NC}"
            return 0
        fi
    else
        if cp -r "$source_folder" "$dest_folder" 2>/dev/null; then
            echo -e "${GREEN}✓ Folder copied successfully${NC}"
            return 0
        elif sudo cp -r "$source_folder" "$dest_folder" 2>/dev/null; then
            echo -e "${GREEN}✓ Folder copied successfully (with sudo)${NC}"
            return 0
        fi
    fi

    echo -e "${RED}✗ Failed to copy folder${NC}"
    return 1
}

#####################
# Git Clone
#####################

# Clones a git repository to a destination path.
# Usage:  git_clone "https://github.com/user/repo.git" "/dest/path" "Description" [branch]
# 4th arg: optional branch name
git_clone() {
    local repo_url="$1"
    local dest_path="$2"
    local description="$3"
    local branch="$4"
    local repo_name
    repo_name=$(basename "$repo_url" .git)

    echo ""
    echo -e "${YELLOW}${BOLD}Cloning repository: ${repo_name}${NC}"
    [ -n "$description" ] && echo -e "${YELLOW}${BOLD}Description: ${description}${NC}"
    echo -e "${YELLOW}Repository:  ${repo_url}${NC}"
    echo -e "${YELLOW}Destination: ${dest_path}${NC}"
    [ -n "$branch" ] && echo -e "${YELLOW}Branch:      ${branch}${NC}"

    # git must be available
    if ! command -v git &>/dev/null; then
        echo -e "${RED}✗ Git is not installed. Please install git first.${NC}"
        return 1
    fi

    # Destination already exists
    if [ -d "$dest_path" ]; then
        if [ -d "$dest_path/.git" ]; then
            echo -e "${BLUE}⊙ Already cloned: ${dest_path}${NC}"
            return 0
        # else
        #     echo -e "${RED}✗ Destination exists but is not a git repository: ${dest_path}${NC}"
        #     echo -e "${YELLOW}Please remove or rename it manually.${NC}"
        #     return 1
        fi
    fi

    # Create parent directory if needed
    local parent_dir
    parent_dir="$(dirname "$dest_path")"
    if [ ! -d "$parent_dir" ]; then
        echo -e "${CYAN}Creating parent directory...${NC}"
        mkdir -p "$parent_dir" 2>/dev/null || sudo mkdir -p "$parent_dir" 2>/dev/null || {
            echo -e "${RED}✗ Failed to create parent directory${NC}"
            return 1
        }
        echo -e "${GREEN}✓ Parent directory created${NC}"
    fi

    # Clone
    echo -e "${CYAN}Cloning repository, please wait...${NC}"
    local clone_args="--progress"
    [ -n "$branch" ] && clone_args="--branch $branch --progress"

    if git clone ${clone_args} "$repo_url" "$dest_path" 2>&1 | while IFS= read -r line; do
        if echo "$line" | grep -qE "Cloning|Receiving|Resolving|Checking"; then
            echo -e "${CYAN}  → ${line}${NC}"
        fi
    done; then
        echo -e "${GREEN}✓ Repository cloned successfully to ${dest_path}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to clone repository${NC}"
        return 1
    fi
}

#####################
# Extract from Zip
#####################

# Extracts a specific folder from a zip file using bsdtar
# Usage:  extract_from_zip "archive.zip" "folder/inside/zip" "/destination" "Description" [strip_components]
# 5th arg: Number of path components to strip (default: 1)
extract_from_zip() {
    local zip_file="$1"
    local target_path="$2"
    local destination="$3"
    local description="$4"
    local strip_components="${5:-1}"

    echo ""
    echo -e "${YELLOW}${BOLD}Extracting from archive: $(basename "$zip_file")${NC}"
    [ -n "$description" ] && echo -e "${YELLOW}${BOLD}Description: ${description}${NC}"
    echo -e "${YELLOW}Archive:     ${zip_file}${NC}"
    echo -e "${YELLOW}Target path: ${target_path}${NC}"
    echo -e "${YELLOW}Destination: ${destination}${NC}"

    # Check if zip file exists
    if [ ! -f "$zip_file" ]; then
        echo -e "${RED}✗ Archive file does not exist: ${zip_file}${NC}"
        return 1
    fi

    # Check if bsdtar is installed
    if ! command -v bsdtar &>/dev/null; then
        echo -e "${YELLOW}bsdtar not found, installing...${NC}"
        if [ "$DISTRO" = "debian" ]; then
            if ! sudo apt-get install -y libarchive-tools &>/dev/null; then
                echo -e "${RED}✗ Failed to install bsdtar (libarchive-tools)${NC}"
                return 1
            fi
        else
            if ! sudo pacman -S --needed --noconfirm libarchive &>/dev/null; then
                echo -e "${RED}✗ Failed to install bsdtar (libarchive)${NC}"
                return 1
            fi
        fi
        echo -e "${GREEN}✓ bsdtar installed${NC}"
    fi

    # Create destination directory if needed
    if [ ! -d "$destination" ]; then
        echo -e "${CYAN}Creating destination directory...${NC}"
        mkdir -p "$destination" 2>/dev/null || sudo mkdir -p "$destination" 2>/dev/null || {
            echo -e "${RED}✗ Failed to create destination directory${NC}"
            return 1
        }
        echo -e "${GREEN}✓ Destination directory created${NC}"
    fi

    # Extract
    echo -e "${CYAN}Extracting files, please wait...${NC}"
    if bsdtar --strip-components="$strip_components" -xf "$zip_file" -C "$destination" "$target_path" 2>&1 | while IFS= read -r line; do
        # Show progress
        if [ -n "$line" ]; then
            echo -e "${CYAN}  → ${line}${NC}"
        fi
    done; then
        echo -e "${GREEN}✓ Successfully extracted to ${destination}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to extract archive${NC}"
        return 1
    fi
}

#####################
# Remove Files/Folders
#####################

# Safely removes files or folders
# Usage:  remove_folder "/path/to/folder" "Description"
# Works with both files and folders
remove_folder() {
    local target="$1"
    local description="$2"

    echo ""
    echo -e "${YELLOW}${BOLD}Removing: $(basename "$target")${NC}"
    [ -n "$description" ] && echo -e "${YELLOW}${BOLD}Description: ${description}${NC}"
    echo -e "${YELLOW}Target: ${target}${NC}"

    # Check if target exists
    if [ ! -e "$target" ]; then
        echo -e "${BLUE}⊙ Target does not exist (already removed): ${target}${NC}"
        return 0
    fi

    # Determine if it's a file or folder
    if [ -f "$target" ]; then
        echo -e "${CYAN}Removing file...${NC}"
        if rm -f "$target" 2>/dev/null || sudo rm -f "$target" 2>/dev/null; then
            echo -e "${GREEN}✓ File removed successfully${NC}"
            return 0
        fi
    elif [ -d "$target" ]; then
        echo -e "${CYAN}Removing folder...${NC}"
        if rm -rf "$target" 2>/dev/null || sudo rm -rf "$target" 2>/dev/null; then
            echo -e "${GREEN}✓ Folder removed successfully${NC}"
            return 0
        fi
    fi

    echo -e "${RED}✗ Failed to remove target${NC}"
    return 1
}

#####################
# Build from Source
#####################

# Builds and installs software from source using make
# Usage:  build_from_source "build_dir" "make_command" "install_command" "Description"
# Example: build_from_source "$PWD" "make" "sudo make install" "Build nautilus plugin"
build_from_source() {
    local build_dir="$1"
    local make_command="$2"
    local install_command="$3"
    local description="$4"

    echo ""
    echo -e "${YELLOW}${BOLD}Building from source${NC}"
    [ -n "$description" ] && echo -e "${YELLOW}${BOLD}Description: ${description}${NC}"
    echo -e "${YELLOW}Build directory: ${build_dir}${NC}"
    echo -e "${YELLOW}Make command:    ${make_command}${NC}"
    echo -e "${YELLOW}Install command: ${install_command}${NC}"

    # Check if build directory exists
    if [ ! -d "$build_dir" ]; then
        echo -e "${RED}✗ Build directory does not exist: ${build_dir}${NC}"
        return 1
    fi

    # Check if make is available
    if ! command -v make &>/dev/null; then
        echo -e "${RED}✗ Make is not installed. Please install make first.${NC}"
        return 1
    fi

    # Change to build directory
    local original_dir="$PWD"
    cd "$build_dir" || {
        echo -e "${RED}✗ Failed to change to build directory${NC}"
        return 1
    }

    # Run make command
    echo -e "${CYAN}Running build command: ${make_command}${NC}"
    if eval "$make_command" 2>&1 | while IFS= read -r line; do
        echo -e "${CYAN}  → ${line}${NC}"
    done; then
        echo -e "${GREEN}✓ Build completed successfully${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
        cd "$original_dir"
        return 1
    fi

    # Run install command
    echo -e "${CYAN}Running install command: ${install_command}${NC}"
    if eval "$install_command" 2>&1 | while IFS= read -r line; do
        echo -e "${CYAN}  → ${line}${NC}"
    done; then
        echo -e "${GREEN}✓ Installation completed successfully${NC}"
        cd "$original_dir"
        return 0
    else
        echo -e "${RED}✗ Installation failed${NC}"
        cd "$original_dir"
        return 1
    fi
}

#####################
# Set GSettings
#####################

# Sets a gsettings value
# Usage:  set_gsetting "schema" "key" "value" "Description"
# Example: set_gsetting "org.gnome.desktop.interface" "color-scheme" "prefer-dark" "Enable dark mode"
set_gsetting() {
    local schema="$1"
    local key="$2"
    local value="$3"
    local description="$4"

    echo ""
    echo -e "${YELLOW}${BOLD}Setting GSettings${NC}"
    [ -n "$description" ] && echo -e "${YELLOW}${BOLD}Description: ${description}${NC}"
    echo -e "${YELLOW}Schema: ${schema}${NC}"
    echo -e "${YELLOW}Key:    ${key}${NC}"
    echo -e "${YELLOW}Value:  ${value}${NC}"

    # Check if gsettings is available
    if ! command -v gsettings &>/dev/null; then
        echo -e "${RED}✗ gsettings is not installed${NC}"
        return 1
    fi

    # Check if schema exists
    if ! gsettings list-schemas | grep -q "^${schema}$"; then
        echo -e "${RED}✗ Schema does not exist: ${schema}${NC}"
        echo -e "${YELLOW}Available schemas can be listed with: gsettings list-schemas${NC}"
        return 1
    fi

    # Set the value
    echo -e "${CYAN}Applying setting...${NC}"
    if gsettings set "$schema" "$key" "$value" 2>&1; then
        # Verify the setting
        local current_value
        current_value=$(gsettings get "$schema" "$key" 2>/dev/null)
        echo -e "${GREEN}✓ Setting applied successfully${NC}"
        echo -e "${CYAN}  Current value: ${current_value}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to apply setting${NC}"
        return 1
    fi
}

#####################
# Compile GLib Schemas
#####################

# Compiles GLib schemas after installing new schema files
# Usage:  compile_glib_schemas "/path/to/schemas" "Description" [use_sudo]
# 3rd arg: "sudo" to force sudo, omit for automatic
compile_glib_schemas() {
    local schema_dir="$1"
    local description="$2"
    local use_sudo="${3:-auto}"

    echo ""
    echo -e "${YELLOW}${BOLD}Compiling GLib schemas${NC}"
    [ -n "$description" ] && echo -e "${YELLOW}${BOLD}Description: ${description}${NC}"
    echo -e "${YELLOW}Schema directory: ${schema_dir}${NC}"

    # Check if directory exists
    if [ ! -d "$schema_dir" ]; then
        echo -e "${RED}✗ Schema directory does not exist: ${schema_dir}${NC}"
        return 1
    fi

    # Check if glib-compile-schemas is available
    if ! command -v glib-compile-schemas &>/dev/null; then
        echo -e "${RED}✗ glib-compile-schemas is not installed${NC}"
        return 1
    fi

    # Compile
    echo -e "${CYAN}Compiling schemas...${NC}"
    if [ "$use_sudo" = "sudo" ]; then
        if sudo glib-compile-schemas "$schema_dir" 2>&1; then
            echo -e "${GREEN}✓ Schemas compiled successfully (with sudo)${NC}"
            return 0
        fi
    else
        if glib-compile-schemas "$schema_dir" 2>/dev/null; then
            echo -e "${GREEN}✓ Schemas compiled successfully${NC}"
            return 0
        elif sudo glib-compile-schemas "$schema_dir" 2>&1; then
            echo -e "${GREEN}✓ Schemas compiled successfully (with sudo)${NC}"
            return 0
        fi
    fi

    echo -e "${RED}✗ Failed to compile schemas${NC}"
    return 1
}

#####################
# Load dconf Settings
#####################

# Loads dconf settings from a backup file
# Usage:  load_dconf_settings "/path/to/backup.bak" "Description" [force]
# 3rd arg: "force" to use -f flag (overwrite non-writable keys)
load_dconf_settings() {
    local backup_file="$1"
    local description="$2"
    local force="${3:-no}"

    echo ""
    echo -e "${YELLOW}${BOLD}Loading dconf settings${NC}"
    [ -n "$description" ] && echo -e "${YELLOW}${BOLD}Description: ${description}${NC}"
    echo -e "${YELLOW}Backup file: ${backup_file}${NC}"

    # Check if backup file exists
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}✗ Backup file does not exist: ${backup_file}${NC}"
        return 1
    fi

    # Check if dconf is available
    if ! command -v dconf &>/dev/null; then
        echo -e "${RED}✗ dconf is not installed${NC}"
        return 1
    fi

    # Load settings
    echo -e "${CYAN}Loading settings from backup...${NC}"
    if [ "$force" = "force" ]; then
        echo -e "${CYAN}Using force mode (will overwrite non-writable keys)${NC}"
        if dconf load -f / <"$backup_file" 2>&1; then
            echo -e "${GREEN}✓ Settings loaded successfully (force mode)${NC}"
            return 0
        fi
    else
        if dconf load / <"$backup_file" 2>&1; then
            echo -e "${GREEN}✓ Settings loaded successfully${NC}"
            return 0
        fi
    fi

    echo -e "${RED}✗ Failed to load settings${NC}"
    return 1
}

#####################
# Add User to Group
#####################

# Adds the current user to one or more groups.
# Usage:  add_user_to_groups "group1" "group2" ...
add_user_to_groups() {
    local groups="$*"

    echo ""
    echo -e "${YELLOW}${BOLD}Adding ${USER} to groups: ${groups}${NC}"

    if [ "$DISTRO" = "debian" ]; then
        for grp in $groups; do
            if sudo adduser "$USER" "$grp" 2>/dev/null; then
                echo -e "${GREEN}✓ Added ${USER} to group: ${grp}${NC}"
            else
                echo -e "${RED}✗ Failed to add ${USER} to group: ${grp}${NC}"
            fi
        done
    else
        local group_list
        group_list=$(echo "$groups" | tr ' ' ',')
        if sudo usermod -aG "$group_list" "$USER" 2>/dev/null; then
            echo -e "${GREEN}✓ Added ${USER} to groups: ${groups}${NC}"
        else
            echo -e "${RED}✗ Failed to add ${USER} to groups: ${groups}${NC}"
        fi
    fi
}

#####################
# Enable Service
#####################

# Enables and starts a systemd service.
# Usage:  enable_service "service-name"
enable_service() {
    local service_name="$1"

    echo ""
    echo -e "${YELLOW}${BOLD}Enabling service: ${service_name}${NC}"

    if sudo systemctl enable --now "$service_name" 2>/dev/null; then
        echo -e "${GREEN}✓ Service enabled and started: ${service_name}${NC}"
    else
        echo -e "${RED}✗ Failed to enable service: ${service_name}${NC}"
        return 1
    fi

    # Show current status
    echo -e "${CYAN}Status:${NC}"
    sudo systemctl status "$service_name" --no-pager -l
}

#####################
# Setup Rust Toolchain (with tmux split)
#####################

# Sets up Rust toolchain using rustup with live output in tmux pane
# Usage:  setup_rust_toolchain [toolchain]
# Default toolchain: stable
setup_rust_toolchain() {
    local toolchain="${1:-stable}"

    echo ""
    echo -e "${YELLOW}${BOLD}Setting up Rust toolchain: ${toolchain}${NC}"

    # Check if rustup is available
    if ! command -v rustup &>/dev/null; then
        echo -e "${RED}✗ rustup is not installed. Please install rustup first.${NC}"
        return 1
    fi

    # Check if already configured
    if rustup show active-toolchain 2>/dev/null | grep -q "$toolchain"; then
        echo -e "${BLUE}⊙ Rust toolchain already configured: ${toolchain}${NC}"
        local rust_version
        rust_version=$(rustc --version 2>/dev/null | awk '{print $2}')
        [ -n "$rust_version" ] && echo -e "${CYAN}  → Rust version: ${rust_version}${NC}"
        return 0
    fi

    # --- Tmux split setup ---
    >"$STATUS_FILE"

    echo -e "${CYAN}Setting up Rust toolchain, please wait (right pane)...${NC}"

    # Simple direct command - shows all rustup output
    tmux split-window -h \
        "bash -c 'rustup default ${toolchain}; echo \$? > ${STATUS_FILE}; sleep 2; exit'"

    # Poll until the right pane writes the exit code
    while [ ! -s "$STATUS_FILE" ]; do
        sleep 0.5
    done

    local exit_code
    exit_code=$(cat "$STATUS_FILE")

    # Ensure focus returns to the main (left) pane
    tmux select-pane -t 0 2>/dev/null || true

    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}✓ Rust toolchain configured successfully: ${toolchain}${NC}"
        # Show current toolchain info
        if command -v rustc &>/dev/null; then
            local rust_version
            rust_version=$(rustc --version 2>/dev/null | awk '{print $2}')
            [ -n "$rust_version" ] && echo -e "${CYAN}  → Rust version: ${rust_version}${NC}"
        fi
        sleep 1
        return 0
    else
        echo -e "${RED}✗ Failed to setup Rust toolchain${NC}"
        sleep 1
        return 1
    fi
}

#####################
# Install Cargo Package (with tmux split)
#####################

# Installs a cargo package with live output in tmux right pane
# Usage:  cargo_install_package "package-name" "Optional description" [--features "feature1,feature2"]
cargo_install_package() {
    local package_name="$1"
    local description="$2"
    shift 2
    local extra_args="$*"

    CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))

    echo ""
    echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Installing cargo package: ${package_name}${NC}"
    if [ -n "$description" ]; then
        echo -e "${YELLOW}Description: ${description}${NC}"
    fi
    [ -n "$extra_args" ] && echo -e "${YELLOW}Extra args: ${extra_args}${NC}"

    # Check if cargo is available
    if ! command -v cargo &>/dev/null; then
        echo -e "${RED}✗ cargo is not installed. Please install Rust first.${NC}"
        return 1
    fi

    # --- Already-installed check ---
    if cargo install --list 2>/dev/null | grep -q "^${package_name} "; then
        echo -e "${BLUE}⊙ Already installed: ${package_name}${NC}"
        # Show version if available
        local version
        version=$(cargo install --list 2>/dev/null | grep "^${package_name} " | awk '{print $2}' | tr -d 'v:()')
        [ -n "$version" ] && echo -e "${CYAN}  → Version: ${version}${NC}"
        return 0
    fi

    # --- Tmux split install ---
    >"$STATUS_FILE"

    echo -e "${CYAN}This may take several minutes as it compiles from source...${NC}"
    echo -e "${CYAN}Installing package, please wait (right pane)...${NC}"

    # Simple direct command - shows ALL cargo output
    tmux split-window -h \
        "bash -c 'cargo install ${package_name} ${extra_args}; echo \$? > ${STATUS_FILE}; sleep 2; exit'"

    # Poll until the right pane writes the exit code
    while [ ! -s "$STATUS_FILE" ]; do
        sleep 0.5
    done

    local exit_code
    exit_code=$(cat "$STATUS_FILE")

    # Ensure focus returns to the main (left) pane
    tmux select-pane -t 0 2>/dev/null || true

    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully installed: ${package_name}${NC}"
        # Show installed version
        local version
        version=$(cargo install --list 2>/dev/null | grep "^${package_name} " | awk '{print $2}' | tr -d 'v:()')
        [ -n "$version" ] && echo -e "${CYAN}  → Version: ${version}${NC}"
        sleep 1
        return 0
    else
        echo -e "${RED}✗ Failed to install: ${package_name}${NC}"
        sleep 1
        return 1
    fi
}

#####################
# Install NPM Package (with tmux split)
#####################

# Installs a global npm package with live output in tmux right pane
# Usage:  npm_install_package "package-name" "Optional description"
npm_install_package() {
    local package_name="$1"
    local description="$2"

    CURRENT_PACKAGE=$((CURRENT_PACKAGE + 1))

    echo ""
    echo -e "${YELLOW}${BOLD}[${CURRENT_PACKAGE}/${TOTAL_PACKAGES}] Installing npm package: ${package_name}${NC}"
    if [ -n "$description" ]; then
        echo -e "${YELLOW}Description: ${description}${NC}"
    fi

    # Check if npm is available
    if ! command -v npm &>/dev/null; then
        echo -e "${RED}✗ npm is not installed. Please install Node.js first.${NC}"
        return 1
    fi

    # --- Already-installed check ---
    if npm list -g --depth=0 2>/dev/null | grep -q " ${package_name}@"; then
        echo -e "${BLUE}⊙ Already installed: ${package_name}${NC}"
        # Show version
        local version
        version=$(npm list -g --depth=0 2>/dev/null | grep " ${package_name}@" | sed 's/.*@//' | awk '{print $1}')
        [ -n "$version" ] && echo -e "${CYAN}  → Version: ${version}${NC}"
        return 0
    fi

    # --- Tmux split install ---
    >"$STATUS_FILE"

    echo -e "${CYAN}Installing package, please wait (right pane)...${NC}"

    # Simple direct command - shows ALL npm output
    tmux split-window -h \
        "bash -c 'npm install -g ${package_name}; echo \$? > ${STATUS_FILE}; sleep 2; exit'"

    # Poll until the right pane writes the exit code
    while [ ! -s "$STATUS_FILE" ]; do
        sleep 0.5
    done

    local exit_code
    exit_code=$(cat "$STATUS_FILE")

    # Ensure focus returns to the main (left) pane
    tmux select-pane -t 0 2>/dev/null || true

    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully installed: ${package_name}${NC}"
        # Show version
        local version
        version=$(npm list -g --depth=0 2>/dev/null | grep " ${package_name}@" | sed 's/.*@//' | awk '{print $1}')
        [ -n "$version" ] && echo -e "${CYAN}  → Version: ${version}${NC}"
        sleep 1
        return 0
    else
        echo -e "${RED}✗ Failed to install: ${package_name}${NC}"
        sleep 1
        return 1
    fi
}

#####################
# Rustup Component Add (with tmux split)
#####################

# Adds a rustup component with live output in tmux pane
# Usage:  rustup_add_component "component-name" "Optional description"
# Examples: rust-src, rust-analyzer, clippy, rustfmt
rustup_add_component() {
    local component_name="$1"
    local description="$2"

    echo ""
    echo -e "${YELLOW}${BOLD}Adding rustup component: ${component_name}${NC}"
    if [ -n "$description" ]; then
        echo -e "${YELLOW}Description: ${description}${NC}"
    fi

    # Check if rustup is available
    if ! command -v rustup &>/dev/null; then
        echo -e "${RED}✗ rustup is not installed. Please install rustup first.${NC}"
        return 1
    fi

    # Check if component is already installed
    if rustup component list --installed 2>/dev/null | grep -q "^${component_name}"; then
        echo -e "${BLUE}⊙ Component already installed: ${component_name}${NC}"
        return 0
    fi

    # --- Tmux split install ---
    >"$STATUS_FILE"

    echo -e "${CYAN}Adding component, please wait (right pane)...${NC}"

    # Simple direct command - shows ALL rustup output
    tmux split-window -h \
        "bash -c 'rustup component add ${component_name}; echo \$? > ${STATUS_FILE}; sleep 2; exit'"

    # Poll until the right pane writes the exit code
    while [ ! -s "$STATUS_FILE" ]; do
        sleep 0.5
    done

    local exit_code
    exit_code=$(cat "$STATUS_FILE")

    # Ensure focus returns to the main (left) pane
    tmux select-pane -t 0 2>/dev/null || true

    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}✓ Component added successfully: ${component_name}${NC}"
        sleep 1
        return 0
    else
        echo -e "${RED}✗ Failed to add component: ${component_name}${NC}"
        sleep 1
        return 1
    fi
}

#####################
# Cleanup on Exit
#####################

# Cleans up the STATUS_FILE when the script ends.
# This runs automatically — do not call manually.
_cleanup_lib() {
    rm -f "$STATUS_FILE"
}
trap _cleanup_lib EXIT
