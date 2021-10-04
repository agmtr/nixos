export ROOT_DISK=/dev/sda

parted -a opt --script "${ROOT_DISK}" \
mklabel gpt \
mkpart primary fat32 0% 512MiB \
mkpart primary 512MiB 100% \
set 1 esp on \
name 1 boot \
name 2 root

cryptsetup luksFormat /dev/sda2
cryptsetup open /dev/sda2 enc

mkfs.fat -F32 -n boot /dev/sda1
mkfs.btrfs /dev/mapper/enc

mount -t btrfs /dev/mapper/enc

btrfs subvolume create /mnt/@nixos
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@swap
btrfs subvolume snapshot -r /mnt/@nixos /mnt/@nixos-blank
umount /mnt

mount -o subvol=@nixos,compress=zstd,noatime,autodefrag /dev/mapper/enc /mnt
mkdir /mnt/home
mount -o subvol=@home,compress=zstd,noatime,autodefrag /dev/mapper/enc /mnt/home
mkdir /mnt/swap
mount -o subvol=@swap /dev/mapper/enc /mnt/home
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

touch /mnt/swap/swapfile
chmod 600 /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile
fallocate /swap/swapfile -l 8G

