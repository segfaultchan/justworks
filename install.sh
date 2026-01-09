#!/bin/bash

# colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"
BOLD="\e[1m"

# vars
NAME=justworks
DISK=none
PART1=none
PART2=none

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

get_script_dir()
{
  local SOURCE_PATH="${BASH_SOURCE[0]}"
  local SYMLINK_DIR
  local SCRIPT_DIR
  # Resolve symlinks recursively
  while [ -L "$SOURCE_PATH" ]; do
    # Get symlink directory
    SYMLINK_DIR="$( cd -P "$( dirname "$SOURCE_PATH" )" >/dev/null 2>&1 && pwd )"
    # Resolve symlink target (relative or absolute)
    SOURCE_PATH="$(readlink "$SOURCE_PATH")"
    # Check if candidate path is relative or absolute
    if [[ $SOURCE_PATH != /* ]]; then
      # Candidate path is relative, resolve to full path
      SOURCE_PATH=$SYMLINK_DIR/$SOURCE_PATH
    fi
  done
  # Get final script directory path from fully resolved source path
  SCRIPT_DIR="$(cd -P "$( dirname "$SOURCE_PATH" )" >/dev/null 2>&1 && pwd)"
  echo "$SCRIPT_DIR"
}

# vars 2
SCRIPT_DIR=$(get_script_dir)
PATH="$PATH:$SCRIPT_DIR/bin"

ct()
{
  local NEXT
  while true; do
    echo "-- continue? [y/n]: "
    read NEXT
  case $NEXT in
    y|Y) break ;;
    n|N) echo -e "${RED}-- aborted..${RESET}"; exit 1 ;;
  esac
  done
}

greeting()
{
  cd "$SCRIPT_DIR"
  figlet -t -c -f ./share/figlet/Delta\ Corps\ Priest\ 1.flf $NAME | lolcat
  echo ""
  echo ""
  echo ""
  echo ""
  # install dependencies
  xi parted
}

network()
{
  echo -e "${RED}-- no networking setup, do it manually${RESET}"
}

partitioning()
{
  echo -e "-- Manual ${RED}partitioning${RESET}"
  echo -e "-- Current disks"
  lsblk -dno NAME,SIZE

  while true; do
    echo "-- which disk do u prefer? "
    read DISK

    if [[ -b "/dev/$DISK" && $DISK != "" ]]; then
      # if correct
      echo -e "-- your choice: ${RED}/dev/$DISK${RESET}"
      break
    fi
      # if dont correct
    lsblk -dno NAME,SIZE
    echo -e "-- disk dont exist${RED} use that format${RESET}: sda"
  done

  echo -e "-- making partitions using ${RED}parted${RESET} in script mode"
  parted -s /dev/$DISK mklabel gpt
  parted -s /dev/$DISK mkpart primary 1MiB 513MiB
  parted -s /dev/$DISK mkpart primary 513MiB 100%
  parted -s /dev/$DISK set 1 esp on
  parted -s /dev/$DISK set 1 boot on
  echo -e "-- ${RED}partitioning done${RESET}"
  parted /dev/$DISK print
}

init_fs_encrypt()
{
  echo -e "-- making ${RED}fat32/btrfs and LUKS${RESET}"

  PART1="/dev/${DISK}1"
  PART2="/dev/${DISK}2"

  if [[ "$DISK" == nvme* ]]; then
    PART1="/dev/${DISK}p1"
    PART2="/dev/${DISK}p2"
  fi

  echo "-- your partitions ${RED}are right?${RESET}"
  echo "PART1=$PART1 PART2=$PART2"

  cryptsetup luksFormat ${PART2} --iter-time=2000 --pbkdf=argon2id --key-size=256 --hash=sha256
  cryptsetup luksOpen ${PART2} root
  
  mkfs.btrfs /dev/mapper/root
  mount /dev/mapper/root /mnt
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@snapshots
  umount /mnt
  mount -o compress=zstd3,subvol=@ /dev/mapper/root /mnt
  mkdir /mnt/{boot,.snapshots}
  mount -o compress=zstd3,subvol=@snapshots /dev/mapper/root /mnt/.snapshots
  
  mkfs.vfat -F 32 /dev/${PART1}
  mount /dev/${PART1}
}

# run
greeting
ct

partitioning
ct

init_fs_encrypt
ct
