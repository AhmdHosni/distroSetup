#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          make-it-accessable.sh
# Created:       Thursday, 19 February 2026 - 01:40 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:   A script to make gimp accessable from commandline
#--------------------------------------------------------------------------------

GIMP_DIR="/media/ahmdhosni/Storage/Apps/Gimp"
VSCODIUM_DIR="/media/ahmdhosni/Storage/Apps/vsCodium"
NVIM_DIR="/media/ahmdhosni/Storage/Apps/Neovim/nvim"
YAZI_DIR="/media/ahmdhosni/Storage/Apps/Yazi"
ANDROID_STUDIO_DIR="/media/ahmdhosni/Storage/Apps/Android/android-studio/bin"
BALENA_ETCHER_DIR="/media/ahmdhosni/Storage/Apps/Balena-Etcher"

GLOBAL_BIN_FOLDER="/usr/local/bin/"

sudo rm -vfr $GLOBAL_BIN_FOLDER/*
## Remove old shortcuts if any exists
if [ -f $GLOBAL_BIN_FOLDER/gimp ]; then sudo rm -vfr $GLOBAL_BIN_FOLDER/gimp; fi
if [ -f $GLOBAL_BIN_FOLDER/vsCodium ]; then sudo rm -vfr $GLOBAL_BIN_FOLDER/vsCodium; fi
if [ -f $GLOBAL_BIN_FOLDER/nvim ]; then sudo rm -vfr $GLOBAL_BIN_FOLDER/nvim; fi
if [ -f $GLOBAL_BIN_FOLDER/yazi ]; then sudo rm -vfr $GLOBAL_BIN_FOLDER/yazi; fi

## copy new shortcuts to /usr/local/bin/ folder
sudo ln -s $GIMP_DIR/GIMP.AppImage $GLOBAL_BIN_FOLDER/gimp
sudo ln -s $VSCODIUM_DIR/VSCodium.AppImage $GLOBAL_BIN_FOLDER/vsCodium
sudo ln -s $NVIM_DIR/nvim-linux.appimage $GLOBAL_BIN_FOLDER/nvim
sudo ln -s $YAZI_DIR/yazi $GLOBAL_BIN_FOLDER/yazi
sudo ln -s $ANDROID_STUDIO_DIR/studio $GLOBAL_BIN_FOLDER/studio
sudo ln -s $BALENA_ETCHER_DIR/balenaEtcher.AppImage $GLOBAL_BIN_FOLDER/balenaEtcher

sudo cp -vfr /media/ahmdhosni/Storage/Settings/hyprland/newDotFiles/version5/aliases.zsh /usr/share/zsh/zshExtras/aliases/aliases.zsh

sudo cp -vfr /media/ahmdhosni/Storage/Settings/hyprland/newDotFiles/version5/exports.zsh /usr/share/zsh/zshExtras/exports/exports.zsh

cp -vfr /media/ahmdhosni/Storage/Settings/hyprland/newDotFiles/version8/.config/nvim/lua/plugins/lsp.lua ~/.config/nvim/lua/plugins/lsp.lua

cp -vfr /media/ahmdhosni/Storage/Settings/hyprland/newDotFiles/version8/.config/nvim/lua/config/keymaps.lua ~/.config/nvim/lua/config/keymaps.lua

cp -vfr /media/ahmdhosni/Storage/Settings/hyprland/newDotFiles/version8/.config/zsh/.zshrc ~/.config/zsh/.zshrc

cp -vfr /media/ahmdhosni/Storage/Settings/hyprland/newDotFiles/version8/.config/kitty/ ~/.config

## Copy new mozilla config folder
if [ -d ~/.config/mozilla ]; then rm -vfr ~/.config/mozilla; fi
cp -vfr /media/ahmdhosni/Storage/Settings/gitRepos/essential/mozilla ~/.config

## Copy new git folder
if [ -d ~/.config/git ]; then rm -vfr ~/.config/git; fi
cp -vfr /media/ahmdhosni/Storage/Settings/gitRepos/git ~/.config

#exit 0
