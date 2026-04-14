echo "Starting cfdisk... (Partition your drive, Write, then Quit)"
# Fix: cfdisk needs the disk path, otherwise it prompts interactively or errors
cfdisk /dev/sda

pacman -Sy --needed --noconfirm efibootmgr networkmanager f2fs-tools dosfstools
sleep 3

echo "Formatting partitions (FAT32 and F2FS)..."
boot_p="/dev/sda1"
root_p="/dev/sda2"

mkfs.fat -F 32 -n UEFI "$boot_p"
sleep 3

# Fix: multiple -O flags consolidated into one comma-separated -O (cleaner, same result)
mkfs.f2fs -f -l ROOT -O extra_attr,inode_checksum,sb_checksum,compression "$root_p"

echo "Mounting root with F2FS optimizations..."
mount -t f2fs -o noatime,lazytime,background_gc=on,atgc,gc_merge,extent_cache,inline_data,inline_dentry,flush_merge,compress_algorithm=lz4,compress_chksum,compress_mode=fs "$root_p" /mnt
sleep 3

mkdir -p /mnt/boot
mount "$boot_p" /mnt/boot
sleep 3

echo "Running pacstrap with Zen kernel..."
# Fix: 'linux-firmware-intel' does not exist in Arch repos — correct package is 'linux-firmware'
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware f2fs-tools intel-ucode git nano networkmanager sudo dosfstools
sleep 3

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
