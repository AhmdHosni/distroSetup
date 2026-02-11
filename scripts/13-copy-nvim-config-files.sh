#!/bin/bash

# creates a .luarc.json file to recognize the neovim paths correctly
# Navigate to your nvim config directory

#####################
# Prepare Directories
#####################

# Get the directory where this script is located

# Get the directory where this script is located
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/libs/lib_functions.sh"
cache_sudo

NVIM_SOURCE_DIR="$THIS_DIR/configs/nvim"

########
# Logic:
########

# 1. Clean up old Neovim files
if [ -d $HOME/.config/nvim ]; then rm -rf $HOME/.config/nvim; fi
if [ -d $HOME/.local/share/nvim ]; then rm -rf $HOME/.local/share/nvim; fi
if [ -d $HOME/.local/state/nvim ]; then rm -rf $HOME/.local/state/nvim; fi
if [ -d $HOME/.cache/nvim ]; then rm -rf $HOME/.cache/nvim; fi

# 2. Install the configuration
copy_folder $NVIM_SOURCE_DIR $HOME/.config

# Create .luarc.json
echo -e "${CYAN}Create .luarc.jason file at nvim root config folder...${NC}"
cd $HOME/.config/nvim/
cat >.luarc.json <<'EOF'
{
  "runtime.version": "LuaJIT",
  "runtime.path": [
    "?.lua",
    "?/init.lua"
  ],
  "diagnostics.globals": ["vim"],
  "workspace.library": [
    "$VIMRUNTIME",
    "${3rd}/luv/library"
  ],
  "workspace.checkThirdParty": false
}
EOF
if [ $? -eq 0 ]; then echo -e "${GREEN}.luarc.json file created successfully ${NC}"; else echo -e "${RED}Creating .luarc.json file failed ! ${NC}"; fi

#################
# Exit the script
#################

exit 0
