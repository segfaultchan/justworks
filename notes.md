# partitioning & encrypt & installing packages & chroot

## variables
`XBPS_ARCH=x86_64-musl`
`REPO=https://repo-default.voidlinux.org/current`

## LUKS
`cryptsetup luksFormat /dev/sdx2 --iter-time=2000 --pbkdf=argon2id --key-size=256 --hash=sha256`
`cryptsetup luksOpen /dev/sdx2 root`

## BTRFS
`mkfs.btrfs -L rootfs /dev/mapper/root`
`mount /dev/mapper/root /mnt`
`cd /mnt`
`btrfs sv cr @`
`btrfs sv cr @home`
`btrfs sv cr @var`
`cd`
`umount /dev/mapper/root`
`mount -o compress=zstd3,subvol=@ /dev/mapper/root /mnt`
`mount -o compress=zstd3,subvol=@home /dev/mapper/root /mnt/home`
`mount -o compress=zstd3,subvol=@var /dev/mapper/root /mnt/var`

## FAT32
`mkfs.vfat -F 32 /dev/sdx1`
`mount /dev/sdx1 /mnt/boot`

## package install to /mnt
`xbps-install -S -r /mnt -R "$REPO" base-system limine terminus-font neovim dhcpcd openresolv sudo`

## generate fstab & chrooting
`xgenfstab -U /mnt > /mnt/etc/fstab`
`xchroot /mnt /bin/bash`

# configuring system

## /etc/rc.conf
