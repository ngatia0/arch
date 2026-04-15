#!/usr/bin/env bash
set -euo pipefail

BOOT_DEV="/dev/sda3"
ROOT_DEV="/dev/sda4"

echo "== Formatting =="
mkfs.fat -F 32 -n UEFI "$BOOT_DEV"
mkfs.f2fs -f -l ROOT -O extra_attr,inode_checksum,sb_checksum,compression "$ROOT_DEV"

echo "== Mounting =="
mount -t f2fs -o noatime,lazytime,background_gc=on,atgc,gc_merge,extent_cache,inline_data,inline_dentry,flush_merge,compress_algorithm=lz4,compress_chksum,compress_mode=fs "$ROOT_DEV" /mnt
mkdir -p /mnt/boot
mount "$BOOT_DEV" /mnt/boot

echo "== Adding CachyOS Repo =="
pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key F3B607488DB35A47
pacman -U --noconfirm 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-latest.pkg.tar.zst'
pacman -U --noconfirm 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-latest.pkg.tar.zst'
pacman -U --noconfirm 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-latest.pkg.tar.zst'

cat >> /etc/pacman.conf << 'EOF'

[cachyos-v3]
Include = /etc/pacman.d/cachyos-v3-mirrorlist

[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist
EOF

pacman -Sy

echo "== Pacstrap =="
pacstrap -K /mnt base base-devel \
    linux-cachyos linux-cachyos-headers \
    linux-firmware-intel \
    f2fs-tools intel-ucode git nano networkmanager sudo dosfstools plymouth

echo "== Fstab =="
genfstab -U /mnt >> /mnt/etc/fstab

echo "== Copying CachyOS repo config to new system =="
cp /etc/pacman.d/cachyos-mirrorlist /mnt/etc/pacman.d/
cp /etc/pacman.d/cachyos-v3-mirrorlist /mnt/etc/pacman.d/
cat >> /mnt/etc/pacman.conf << 'EOF'

[cachyos-v3]
Include = /etc/pacman.d/cachyos-v3-mirrorlist

[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist
EOF

echo "------------------------------------------"
echo " ✅ Done — now run arch-chroot /mnt"
echo "------------------------------------------"
