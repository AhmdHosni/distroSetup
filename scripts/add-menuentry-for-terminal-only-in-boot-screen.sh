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

    # Script to add Terminal Mode to Arch Linux GRUB
    cat <<'EOF' | sudo tee -a /etc/grub.d/40_custom

menuentry 'Arch Linux (Terminal Mode)' --class arch --class gnu-linux {
    load_video
    set gfxpayload=keep
    insmod gzio
    insmod part_gpt
    insmod fat
    search --no-floppy --fs-uuid --set=root E802-AD2C
    echo    'Loading Linux linux-lts (CLI)...'
    linux   /vmlinuz-linux-lts root=UUID=b71b6889-5942-46de-ab4b-1cf6185506eb rw rootflags=subvol=@ zswap.enabled=0 rootfstype=btrfs loglevel=3 quiet systemd.unit=multi-user.target
    echo    'Loading initial ramdisk ...'
    initrd  /intel-ucode.img /initramfs-linux-lts.img
}
EOF

    # Update GRUB configuration
    sudo grub-mkconfig -o /boot/grub/grub.cfg

fi

# Exit the Script
exit 0
