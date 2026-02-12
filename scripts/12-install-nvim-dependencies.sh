#!/bin/bash

# -----------------------------------------------------------------------------------------------
# File Name: install-nvim-dependencies.sh
# Adapted for: Debian 13 (Trixie) and Arch Linux
# Description: Installs LazyVim and dependencies using apt and pacman with improved Rust/Cargo support
# ------------------------------------------------------------------------------------------------

# Get the directory where this script is located
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"
start_tmux
cache_sudo

########################
## Setting the folders
########################

NVIM_SOURCE_DIR="$THIS_DIR/configs/nvim"

# Create necessary directories
mkdir -p ~/.config/npm
mkdir -p ~/.local/share/npm
mkdir -p ~/.cache/npm

#####################
# Calculate Total Packages
#####################

# Count packages based on detected distro
if [ "$DISTRO" = "debian" ]; then
    TOTAL_PACKAGES=24 # Updated: 21 apt packages + 1 rust setup + 1 cargo + 1 npm
else
    TOTAL_PACKAGES=13 # Manual count for Arch packages
fi
echo ""
echo -e "${CYAN}${BOLD}Total packages to process: ${TOTAL_PACKAGES}${NC}"

######################
# INSTALLING PACKAGES
#####################

if [ "$DISTRO" = "debian" ]; then
    # echo ""
    # echo -e "${CYAN}${BOLD}========================================${NC}"
    # echo -e "${CYAN}${BOLD}  Installing Core Requirements${NC}"
    # echo -e "${CYAN}${BOLD}========================================${NC}"

    show_title "Installing Core Requirements"

    install_package "fonts-noto-color-emoji" "Colored emoji fonts for better icon support"
    install_package "git" "Distributed version control system"
    install_package "build-essential" "Essential compilation tools"
    install_package "curl" "Command-line tool for transferring data"
    install_package "xclip" "Command-line clipboard utility"
    install_package "python3-pip" "Python package installer"
    install_package "python3-venv" "Python virtual environment support"

    # echo ""
    # echo -e "${CYAN}${BOLD}========================================${NC}"
    # echo -e "${CYAN}${BOLD}  Installing Tools & Utilities${NC}"
    # echo -e "${CYAN}${BOLD}========================================${NC}"

    show_title "Installing Tools & Utilities"

    install_package "lazygit" "Simple terminal UI for git commands"
    install_package "fzf" "Command-line fuzzy finder"
    install_package "ripgrep" "Fast search tool (rg)"
    install_package "fd-find" "Fast alternative to find command"

    # echo ""
    # echo -e "${CYAN}${BOLD}========================================${NC}"
    # echo -e "${CYAN}${BOLD}  Installing Language Support${NC}"
    # echo -e "${CYAN}${BOLD}========================================${NC}"

    show_title "Installing Language Support"

    install_package "luarocks" "Lua package manager for tree-sitter"
    install_package "kitty" "Modern GPU-accelerated terminal emulator"
    install_package_no_recommendations "python3-pynvim" "Python provider for Neovim"
    install_package "npm" "Node.js package manager"

    # echo ""
    # echo -e "${CYAN}${BOLD}========================================${NC}"
    # echo -e "${CYAN}${BOLD}  Installing Rust Dependencies${NC}"
    # echo -e "${CYAN}${BOLD}========================================${NC}"

    show_title "Installing Rust Dependencies"

    install_package "wget" "Network downloader"
    install_package "rustup" "Rust toolchain installer"
    install_package "libclang-dev" "Clang library development files"
    install_package "clang" "C language family frontend for LLVM"

    # echo ""
    # echo -e "${CYAN}${BOLD}========================================${NC}"
    # echo -e "${CYAN}${BOLD}  Setting Up Rust Toolchain${NC}"
    # echo -e "${CYAN}${BOLD}========================================${NC}"

    show_title "Setting Up Rust Toolchain"

    # Setup Rust toolchain using the new function
    setup_rust_toolchain "stable"

    # echo ""
    # echo -e "${CYAN}${BOLD}========================================${NC}"
    # echo -e "${CYAN}${BOLD}  Installing Rust Packages${NC}"
    # echo -e "${CYAN}${BOLD}========================================${NC}"

    show_title "Installing Rust Packages"

    # Install tree-sitter-cli using the new cargo function
    cargo_install_package "tree-sitter-cli" "Tree-sitter parser generator and CLI"

    # echo ""
    # echo -e "${CYAN}${BOLD}========================================${NC}"
    # echo -e "${CYAN}${BOLD}  Installing NPM Packages${NC}"
    # echo -e "${CYAN}${BOLD}========================================${NC}"

    show_title "Installing NPM Packages"

    # Install neovim npm package using the new npm function
    npm_install_package "neovim" "Neovim Node.js provider"

elif [ "$DISTRO" = "arch" ]; then

    # echo ""
    # echo -e "${CYAN}${BOLD}========================================${NC}"
    # echo -e "${CYAN}${BOLD}  Installing Core Requirements${NC}"
    # echo -e "${CYAN}${BOLD}========================================${NC}"

    show_title "Installing Core Requirements"

    install_package "git" "Distributed version control system"
    install_package "lazygit" "Simple terminal UI for git commands"

    # echo ""
    # echo -e "${CYAN}${BOLD}========================================${NC}"
    # echo -e "${CYAN}${BOLD}  Installing Tree-sitter & Compiler${NC}"
    # echo -e "${CYAN}${BOLD}========================================${NC}"

    show_title "Installing Tree-sitter & Compiler"

    install_package "tree-sitter-cli" "Tree-sitter command-line interface"
    install_package "gcc" "GNU C compiler for nvim-treesitter"

    # echo ""
    # echo -e "${CYAN}${BOLD}========================================${NC}"
    # echo -e "${CYAN}${BOLD}  Installing Tools & Utilities${NC}"
    # echo -e "${CYAN}${BOLD}========================================${NC}"

    show_title "Installing Tools & Utilities"

    install_package "curl" "Command-line tool for transferring data"
    install_package "fzf" "Command-line fuzzy finder"
    install_package "ripgrep" "Fast search tool (rg)"
    install_package "fd" "Fast alternative to find command"

    # echo ""
    # echo -e "${CYAN}${BOLD}========================================${NC}"
    # echo -e "${CYAN}${BOLD}  Installing Language Support${NC}"
    # echo -e "${CYAN}${BOLD}========================================${NC}"

    show_title "Installing Language Support"

    install_package "kitty" "Modern GPU-accelerated terminal emulator"
    install_package "luarocks" "Lua package manager for tree-sitter"
    install_package "wget" "Network downloader"
    install_package "python-pip" "Python package installer"
    install_package "python-pynvim" "Python provider for Neovim"
    install_package "npm" "Node.js package manager"

fi

show_title "Installation Complete!" "All Neovim dependencies have been installed"

# echo ""
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo -e "${GREEN}${BOLD}  Installation Complete!${NC}"
# echo -e "${CYAN}${BOLD}========================================${NC}"
# echo ""
# echo -e "${GREEN}All Neovim dependencies have been installed.${NC}"
# echo -e "${YELLOW}${BOLD}Open Neovim to allow Lazy.nvim to install plugins.${NC}"
# echo ""

# ------------------------------------------------------------------------------------------------
# LazyVim Installation Steps (Commented out - uncomment if needed)
# ------------------------------------------------------------------------------------------------

# 1. Clean up old Neovim files
# echo -e "${YELLOW}${BOLD}Cleaning up old Neovim configuration...${NC}"
# rm -rf ~/.config/nvim
# rm -rf ~/.local/share/nvim
# rm -rf ~/.local/state/nvim
# rm -rf ~/.cache/nvim
# echo -e "${GREEN}✓ Old configuration removed${NC}"

# 2. Clone the starter
# echo ""
# echo -e "${YELLOW}${BOLD}Cloning LazyVim starter configuration...${NC}"
# git clone https://github.com/LazyVim/starter ~/.config/nvim
# echo -e "${GREEN}✓ LazyVim starter cloned${NC}"

# 3. Remove .git folder
# echo ""
# echo -e "${YELLOW}${BOLD}Removing .git folder...${NC}"
# rm -rf ~/.config/nvim/.git
# echo -e "${GREEN}✓ .git folder removed${NC}"

# ------------------------------------------------------------------------------------------------
# Personal Config Migration (Commented out - uncomment and modify paths as needed)
# ------------------------------------------------------------------------------------------------

# echo ""
# echo -e "${YELLOW}${BOLD}Copying personal configurations...${NC}"
#
# # Copy nvim config folder to ~/.config/
# if cp -vr $NVIM_SOURCE_DIR $HOME/.config 2>/dev/null; then
#     echo -e "${GREEN}✓ Nvim config copied successfully${NC}"
# else
#     echo -e "${RED}✗ Nvim config copy failed${NC}"
# fi
#
# # Create .luarc.json
# cd $HOME/.config/nvim/
# cat >.luarc.json <<'EOF'
# {
#   "runtime.version": "LuaJIT",
#   "runtime.path": [
#     "?.lua",
#     "?/init.lua"
#   ],
#   "diagnostics.globals": ["vim"],
#   "workspace.library": [
#     "$VIMRUNTIME",
#     "${3rd}/luv/library"
#   ],
#   "workspace.checkThirdParty": false
# }
# EOF
# echo -e "${GREEN}✓ .luarc.json created${NC}"

##################
# Exit the Script
#################
exit 0
