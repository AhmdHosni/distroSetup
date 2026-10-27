#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          enable_arduino_permissions.sh
# Created:       Monday, 07 September 2026 - 10:35 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:
#--------------------------------------------------------------------------------

if command -v pacman &>/dev/null; then
    # Add your current user to the uucp group
    # so you always have read/write access to serial devices.
    sudo usermod -a -G uucp $USER
    # Log out then log back in
    # You can apply the group changes immediately to your current terminal session
    # without logging out or restarting by using the newgrp command.
    newgrp uucp
elif command -v apt-get &>/dev/null; then
    # Add your user to the dialout group
    sudo usermod -a -G dialout $USER
    # Log out and back in
    # To use the new group permissions immediately without logging out, you can use the newgrp command.
    # This command starts a new shell session within your terminal that recognizes your updated group membership.
    newgrp dialout
fi
