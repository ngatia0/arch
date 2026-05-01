#!/usr/bin/env bash

# --- Configuration ---
USERNAME="kvnx"
HOSTNAME="archiso"
DISK="/dev/sda"
BOOT_DEV="${DISK}1"
ROOT_DEV="${DISK}2"

echo "== Starting Arch Linux Installation for $USERNAME =="

# 1. Preparation
pacman -Sy --needed --noconfirm efibootmgr networkmanager f2fs-tools dosfstools
cfdisk "$DISK"

# 2. Formatting
echo "Formatting $BOOT_DEV (FAT32) and $ROOT_DEV (F2FS)..."
mkfs.fat -F 32 -n UEFI "$BOOT_DEV"
mkfs.f2fs -f -l ROOT -O extra_attr,inode_checksum,sb_checksum,compression "$ROOT_DEV"

# 3. Mounting with optimized F2FS flags
mount -t f2fs -o noatime,lazytime,background_gc=on,atgc,gc_merge,extent_cache,inline_data,inline_dentry,flush_merge,compress_algorithm=lz4,compress_chksum,compress_mode=fs "$ROOT_DEV" /mnt
mkdir -p /mnt/boot
mount "$BOOT_DEV" /mnt/boot

# 4. Base Installation
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware f2fs-tools intel-ucode git nano networkmanager sudo plymouth

# 5. Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# 6. Generate the Chroot Setup Script
cat << 'EOF' > /mnt/setup.sh
#!/usr/bin/env bash

USERNAME="kvnx"
HOSTNAME="archiso"

echo "Setting up $HOSTNAME..."

# Localization
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc
echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname

# Network
cat << EOH > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOH

# Users & Permissions
useradd -m -G wheel,audio,video -s /bin/bash "$USERNAME"
echo "Set password for $USERNAME:"
passwd "$USERNAME"
echo "Set root password:"
passwd

echo "Opening visudo... Please uncomment %wheel ALL=(ALL:ALL) ALL"
EDITOR=nano visudo


# Bootloader (Systemd-boot)
# Fix: --esp-path replaces deprecated --path
bootctl install --esp-path=/boot

# Detect UUID of root partition safely from inside chroot
ROOT_UUID=$(blkid -s UUID -o value "$(findmnt -n -o SOURCE /)")

cat << EOT > /boot/loader/loader.conf
default arch-zen.conf
timeout 3
console-mode max
editor no
EOT

cat << EOT > /boot/loader/entries/arch-zen.conf
title   Arch Linux (Zen)
linux   /vmlinuz-linux-zen
initrd  /intel-ucode.img
initrd  /initramfs-linux-zen.img
options root=UUID=$ROOT_UUID rw rootfstype=f2fs quiet splash
EOT
cat << EOT > /boot/loader/entries/cachyos.conf
title   CachyOS
linux   /vmlinuz-linux-cachyos
initrd  /intel-ucode.img
initrd  /initramfs-linux-cachyos.img
options root=UUID=$ROOT_UUID rw rootfstype=f2fs quiet splash
EOT

cat << EOT > /boot/loader/entries/cachyos-bore.conf
title   CachyOS-Bore
linux   /vmlinuz-linux-cachyos-bore-lto
initrd  /intel-ucode.img
initrd  /initramfs-linux-cachyos-bore-lto.img
options root=UUID=$ROOT_UUID rw rootfstype=f2fs quiet splash
EOT

# Initramfs
# Fix: use 'sd-plymouth' (pairs with systemd hook), not 'plymouth' (udev/busybox only)
cat << EOT > /etc/mkinitcpio.conf
MODULES=(f2fs i915)
BINARIES=()
FILES=()
HOOKS=(base systemd plymouth autodetect modconf kms sd-vconsole block filesystems fsck)
EOT

mkinitcpio -p linux-zen

systemctl enable NetworkManager
EOF

# 7. Finalize
chmod +x /mnt/setup.sh
arch-chroot /mnt ./setup.sh
rm /mnt/setup.sh

echo "------------------------------------------"
echo " ✅ INSTALLATION COMPLETE"
echo " Run: umount -R /mnt && reboot"
echo "------------------------------------------"
