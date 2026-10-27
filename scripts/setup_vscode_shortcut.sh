#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          setup_vscode_shortcut.sh
# Created:       Monday, 07 September 2026 - 10:54 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:
#--------------------------------------------------------------------------------

# Define paths
SCRIPT_DIR="$HOME/.local/bin"
SCRIPT_PATH="$SCRIPT_DIR/vscode"
DESKTOP_ENTRY_PATH="$HOME/.local/share/applications/vscode.desktop"
VSCODE_FOLDER_DIR="/media/$USER/Storage/Apps/vsCode/VSCode/bin"

GLOBAL_BIN_FOLDER="/usr/local/bin"

### Enable Arduino and other microcontrollers USP access
if command -v pacman &>/dev/null; then
    # Add your current user to the uucp group
    # so you always have read/write access to serial devices.
    sudo usermod -a -G uucp $USER
    # Log out then log back in
    # You can apply the group changes immediately to your current terminal session
    # without logging out or restarting by using the newgrp command.
    # newgrp uucp
elif command -v apt-get &>/dev/null; then
    # Add your user to the dialout group
    sudo usermod -a -G dialout $USER
    # Log out and back in
    # To use the new group permissions immediately without logging out, you can use the newgrp command.
    # This command starts a new shell session within your terminal that recognizes your updated group membership.
    # newgrp dialout
fi

# add shortcut to /usr/local/bin
# remove any shortcut if any:
if [ -f $GLOBAL_BIN_FOLDER/code ]; then sudo rm -vfr $GLOBAL_BIN_FOLDER/code; fi
# add the shortcut:
sudo ln -s $VSCODE_FOLDER_DIR/code $GLOBAL_BIN_FOLDER/code

# 1. Create the local bin directory if it doesn't exist
mkdir -p "$SCRIPT_DIR"

# 2. Write the VSCode execution script
cat <<'EOF' >"$SCRIPT_PATH"
#!/usr/bin/env bash

vsCode_data="/media/$USER/Storage/Apps/vsCode/VSCode/data"

# Check if an argument was actually passed to the script
if [ $# -gt 0 ]; then
    # Arguments exist (e.g., a specific folder path was passed)
    /usr/local/bin/code --disable-workspace-trust \
        --user-data-dir "$vsCode_data/user-data" \
        --extensions-dir "$vsCode_data/extensions" \
        "$@" >/dev/null 2>&1 &
    disown
else
    # No arguments (e.g., clicked from desktop shortcut).
    # Let VS Code restore its previous session natively without forcing a folder.
    /usr/local/bin/code --disable-workspace-trust \
        --user-data-dir "$vsCode_data/user-data" \
        --extensions-dir "$vsCode_data/extensions" \
        >/dev/null 2>&1 &
    disown
fi
EOF

# Make the execution script executable
chmod +x "$SCRIPT_PATH"

# 3. Create the .desktop shortcut
cat <<EOF >"$DESKTOP_ENTRY_PATH"
[Desktop Entry]
Version=1.0
Type=Application
Name=VSCode
Comment=Launch VSCode with custom data and extension directories
Exec=$SCRIPT_PATH
Icon=/media/ahmdhosni/Storage/Apps/vsCode/VSCode/resources/app/resources/linux/code.png
Terminal=false
Categories=Development;IDE;TextEditor;
StartupWMClass=Code
EOF

# Make the desktop entry executable (required by some desktop environments)
chmod +x "$DESKTOP_ENTRY_PATH"

echo "✅ Setup complete!"
echo "🚀 Script created at: $SCRIPT_PATH"
echo "🖥️  Desktop shortcut created at: $DESKTOP_ENTRY_PATH"
echo "💡 You can now find 'VSCode (Custom Storage)' in your application menu."
