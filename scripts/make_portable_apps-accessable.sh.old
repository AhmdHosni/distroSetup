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

exit 0
