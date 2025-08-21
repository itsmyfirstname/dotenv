#!/bin/zsh

# Run with sudo

efibootmgr --create --disk /dev/nvme0n1 --part 1 --label "Arch Linux" --loader /vmlinuz-linux --unicode 'root=UUID=1c532788-8337-44c9-b867-0b96d6c0ee26 rw initrd=\initramfs-linux.img'

#pacman -S systemd-ukify

#ukify genkey --config /etc/kernel/uki.conf

