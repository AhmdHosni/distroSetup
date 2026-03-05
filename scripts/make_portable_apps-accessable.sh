#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          make-it-accessable.sh
# Created:       Thursday, 19 February 2026 - 01:40 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:   A script to make gimp accessable from commandline
#--------------------------------------------------------------------------------

GIMP_DIR="/media/ahmdhosni/Storage/Apps/gimp"
VSCODE_DIR="/media/ahmdhosni/Storage/Apps/vsCode/VSCode"
GLOBAL_BIN_FOLDER="/usr/local/bin/"

sudo ln -s $GIMP_DIR/GIMP.AppImage $GLOBAL_BIN_FOLDER/gimp
sudo ln -s $VSCODE_DIR/code $GLOBAL_BIN_FOLDER/code

exit 0
