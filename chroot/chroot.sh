USERNAME="kvnx"
HOSTNAME="archiso"
ROOT_DEV="/dev/sda2"

echo "=========================================="
echo " 1. CREATING USERNAME & HOSTNAME          "
echo "=========================================="
echo "$HOSTNAME" > /etc/hostname
useradd -m -g users -G wheel,audio,video -s /bin/bash "$USERNAME"
echo "Set a password for $USERNAME:"
passwd "$USERNAME"
echo "Setting up hosts file..."
echo "127.0.0.1       localhost" > /etc/hosts
echo "::1             localhost" >> /etc/hosts
# Fix: was $hostname (lowercase) — bash is case-sensitive, variable was never set
echo "127.0.1.1       $HOSTNAME" >> /etc/hosts
cat /etc/hosts
echo "Enter ROOT PASSWORD"
passwd

echo "=========================================="
echo " 2. LOCALE & VCONSOLE STUFF               "
echo "=========================================="
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc
echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

echo "=========================================="
echo " 3. MANUAL VISUDO CONFIGURATION           "
echo "=========================================="
echo "Opening visudo... Please uncomment %wheel ALL=(ALL:ALL) ALL"
echo "Press ENTER to continue..."
read -r
EDITOR=nano visudo

echo "=========================================="
echo " 4. BOOTLOADER CONFIGURATION              "
echo "=========================================="
# Fix: --path is deprecated, use --esp-path
bootctl install --esp-path=/boot

cat <<EOT > /boot/loader/loader.conf
default arch-zen.conf
timeout 3
console-mode max
editor no
EOT

ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEV")

cat <<EOT > /boot/loader/entries/arch-zen.conf
title   Zen
linux   /vmlinuz-linux-zen
initrd  /intel-ucode.img
initrd  /initramfs-linux-zen.img
options root=UUID=$ROOT_UUID rw rootfstype=f2fs quiet splash
EOT

echo "=========================================="
echo " 5. MKINITCPIO (F2FS + INTEL + PLYMOUTH)  "
echo "=========================================="
cat <<EOT > /etc/mkinitcpio.conf
MODULES=(f2fs i915)
BINARIES=()
FILES=()
# Fix: sd-plymouth pairs with the systemd hook — 'plymouth' is for udev/busybox only
HOOKS=(systemd sd-plymouth autodetect microcode modconf kms sd-vconsole block filesystems fsck)
EOT

# Fix: was 'linux-zenpkill' — typo, correct preset name is 'linux-zen'
mkinitcpio -p linux-zen

echo "=========================================="
echo " 6. ENABLING SERVICES                     "
echo "=========================================="
systemctl enable NetworkManager

echo "=========================================="
echo " ✅ SYSTEM SETUP COMPLETE!                 "
echo " Type 'exit', 'umount -R /mnt', and reboot"
echo "=========================================="
