# partitioning & encrypt & installing packages & chroot

## variables
`XBPS_ARCH=x86_64`
`REPO=https://repo-default.voidlinux.org/current`

## LUKS
`cryptsetup luksFormat /dev/sdx2 --iter-time=2000 --pbkdf=argon2id --key-size=256 --hash=sha256`
`cryptsetup luksOpen /dev/sdx2 root`

## BTRFS
`mkfs.btrfs -L rootfs /dev/mapper/root`
`mount /dev/mapper/root /mnt`
`cd /mnt`
`btrfs subvolume create @`
`btrfs subvolume create @home`
`btrfs subvolume create @var`
`cd`
`umount /dev/mapper/root`
`mount -o compress=zstd3,subvol=@ /dev/mapper/root /mnt`
`mount -o compress=zstd3,subvol=@home /dev/mapper/root /mnt/home`
`mount -o compress=zstd3,subvol=@var /dev/mapper/root /mnt/var`

## FAT32
`mkfs.vfat -F 32 /dev/sdx1`
`mount /dev/sdx1 /mnt/boot`

## package install to /mnt
```
xbps-install -S -r /mnt -R "$REPO" \
base-system xtools cryptsetup limine efibootmgr \
terminus-font neovim dhcpcd openresolv sudo
```

## generate fstab & chrooting
`xgenfstab -U /mnt > /mnt/etc/fstab`
`xchroot /mnt /bin/bash`

# configuring system

### /etc/rc.conf
uncomment
```
HARDWARECLOCK="localtime"
TIMEZONE="Europe/Moscow"
KEYMAP="us"
FONT="ter-u28b"
```

## /etc/default/libc-locales
uncomment locales

`xbps-reconfigure -f glibc-locales`

## hostname
`echo "*name*" > /etc/hostname`

## runit (sv)
```
# services store in /etc/sv
# link service dir to /var/service to activate it
ln -s /etc/sv/*service* /var/service
```
# initramfs & bootloader & cryptsetup

## dracut

### /etc/dracut.conf
`install_items+=" /etc/crypttab "`

### /etc/crypttab
`root   /dev/sdx2   none    luks`

```
# correct rights
chmod -R g-rwx,o-rwx /boot

```

# set password to root
`passwd`

## dracut

### update dracut
`xbps-reconfigure -fa`

## limine setup
```
# copy efi image limine to esp:
mkdir -p /boot/EFI/limine
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine
# adding bootloader to nvram manually
efibootmgr \
  --create \
  --disk /dev/sdX \
  --part Y \
  --label "Limine Boot Loader" \
  --loader '\EFI\limine\BOOTX64.EFI' \
  --unicode
# configuring limine
mkdir /boot/limine
```

### /boot/limine/limine.conf
```
timeout: 0
/Void
  protocol: linux
  path: boot():/vmlinuz-*kernel-version*
  cmdline: rd.luks.uuid=<UUID> root=/dev/mapper/root rootfstype=btrfs rootflags=subvol=@ rw
  module_path: boot():/initramfs-*kernel-version*.img
```

check UUID
`blkid -o value -s UUID /dev/sdx2`
