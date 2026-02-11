#!/bin/bash

# This runs as root/user
# Don't source lib_functions here

if command -v apt-get &>/dev/null; then
    # Define the path for the drop-in sudoers file
    SUDOERS_FILE="/etc/sudoers.d/disable-admin-flag"

    # Create the configuration line
    # 'Defaults !admin_flag' tells sudo not to create the .sudo_as_admin_successful file
    CONFIG_LINE="Defaults !admin_flag"

    echo "Applying sudoers change to disable the admin flag..."

    # Use a temporary file to validate syntax before applying
    TMP_FILE=$(mktemp)
    echo "$CONFIG_LINE" >"$TMP_FILE"

    # Check the syntax of the temporary file using visudo
    if sudo visudo -cf "$TMP_FILE"; then
        # If syntax is valid, move it to the official directory with correct permissions
        sudo mv "$TMP_FILE" "$SUDOERS_FILE"
        sudo chmod 0440 "$SUDOERS_FILE"
        sudo chown root:root "$SUDOERS_FILE"

        # Remove existing flag file from the home directory
        [ -f ~/.sudo_as_admin_successful ] && rm ~/.sudo_as_admin_successful

        echo "Success: Admin flag disabled and existing file removed."
    else
        echo "Error: Syntax validation failed. No changes were made."
        rm "$TMP_FILE"
        exit 1
    fi

else
    echo -e "${YELLOW}${BOLD}\nThis script is intended for Debian distribution only, this is not a debian destribution so no need to apply this script${NC}"
fi

# exit the script
exit 0
