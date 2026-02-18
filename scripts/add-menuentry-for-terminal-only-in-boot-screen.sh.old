#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          add_menu_entry.sh
# Created:       Saturday, 14 February 2026 - 06:04 PM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:
#--------------------------------------------------------------------------------

if command -v apt-get &>/dev/null; then

    # Script to add Terminal Mode to Debian GRUB
    cat <<'EOF' | sudo tee -a /etc/grub.d/40_custom

menuentry 'Debian GNU/Linux (Terminal Mode)' --class debian --class gnu-linux {
    load_video
    insmod gzio
    insmod part_gpt
    insmod btrfs
    search --no-floppy --fs-uuid --set=root 440a4762-4a3d-4d57-b2c8-94cdeb5f6081
    echo    'Loading Linux 6.12.69+deb13-amd64 (CLI)...'
    linux   /@/boot/vmlinuz-6.12.69+deb13-amd64 root=UUID=440a4762-4a3d-4d57-b2c8-94cdeb5f6081 ro rootflags=subvol=@ quiet systemd.unit=multi-user.target
    echo    'Loading initial ramdisk ...'
    initrd  /@/boot/initrd.img-6.12.69+deb13-amd64
}
EOF

    # Update GRUB configuration
    sudo update-grub

elif command -v pacman &>/dev/null; then

    # Detect running kernel release
    KERNEL_RELEASE=$(uname -r)

    if [[ "$KERNEL_RELEASE" == *"-lts"* ]]; then
        echo "Detected Arch LTS. Adding LTS Terminal Entry..."
        cat <<'EOF' | sudo tee -a /etc/grub.d/40_custom

menuentry 'Arch Linux (LTS - Terminal Mode)' --class arch --class gnu-linux {
    load_video
    set gfxpayload=keep
    insmod gzio
    insmod part_gpt
    insmod fat
    search --no-floppy --fs-uuid --set=root E802-AD2C
    echo    'Loading Linux linux-lts (CLI)...'
    linux   /vmlinuz-linux-lts root=UUID=b71b6889-5942-46de-ab4b-1cf6185506eb rw rootflags=subvol=@ zswap.enabled=0 rootfstype=btrfs loglevel=3 quiet systemd.unit=multi-user.target
    initrd  /intel-ucode.img /initramfs-linux-lts.img
}
EOF

    elif [[ "$KERNEL_RELEASE" == *"-zen"* ]]; then
        echo "Detected Arch Zen. Adding Zen Terminal Entry..."
        cat <<'EOF' | sudo tee -a /etc/grub.d/40_custom

menuentry 'Arch Linux (Zen - Terminal Mode)' --class arch --class gnu-linux {
    load_video
    set gfxpayload=keep
    insmod gzio
    insmod part_gpt
    insmod fat
    search --no-floppy --fs-uuid --set=root 3A35-B2ED
    echo    'Loading Linux linux-zen (CLI)...'
    linux   /vmlinuz-linux-zen root=UUID=3c633f0a-a25f-448c-951b-e4e367fbf1fd rw rootflags=subvol=@ zswap.enabled=0 rootfstype=btrfs loglevel=3 quiet systemd.unit=multi-user.target
    initrd  /intel-ucode.img /initramfs-linux-zen.img
}
EOF

    else
        echo "Kernel not recognized as LTS or Zen ($KERNEL_RELEASE)."
    fi

    # Apply changes
    sudo grub-mkconfig -o /boot/grub/grub.cfg

fi

# Exit the Script
exit 0
