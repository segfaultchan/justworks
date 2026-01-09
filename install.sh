#!/bin/bash

# colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"
BOLD="\e[1m"

# important
NAME=justworks
DISK=none
PART1=none
PART2=none

DEPS="parted"
NOT_FIRST_LAUNCH_FILE="./not_first_launch"

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
    n|N) echo -e "-- ${RED}aborted..${RESET}"; exit 1 ;;
  esac
  done
}

reset_steps() {
  if [[ ! -f "$NOT_FIRST_LAUNCH_FILE" ]]; then
    return
  fi
  echo "-- starting reset ${RED}past installation${RESET}"
  if mountpoint -q /mnt; then
    umount -R /mnt
  fi
  if cryptsetup status root; then
    cryptsetup luksClose root
  fi
  echo -e "-- past installation ${RED}was reset${RESET}"
}

step0()
{
  # sign about launch (for reset)
  touch "$NOT_FIRST_LAUNCH_FILE"
  # checking internet connection
  set +e
  if curl -s --head https://google.com --max-time 5 >/dev/null; then
    echo -e "-- ${RED}internet connected${RESET}"
  else
    echo -e "${RED}-- no networking setup, do it manually${RESET}"
    exit 1
  fi
  set -e

  # continue
  ct
}

step1()
{
  # print logo
  echo -e "-- ${GREEN}STEP 1${RESET}"
  cd "$SCRIPT_DIR"

  echo ""
  echo ""
  figlet -t -c -f ./share/figlet/Delta\ Corps\ Priest\ 1.flf $NAME | lolcat
  echo ""
  echo ""
  # install dependencies
  xi "$DEPS"

  # continue
  ct
}

step2()
{
  # partitioning
  echo -e "-- ${GREEN}STEP 2${RESET}"
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
  wipefs --all /dev/$DISK
  parted -s /dev/$DISK mklabel gpt
  parted -s /dev/$DISK mkpart primary 1MiB 513MiB
  parted -s /dev/$DISK mkpart primary 513MiB 100%
  parted -s /dev/$DISK set 1 esp on
  parted -s /dev/$DISK set 1 boot on
  echo -e "-- ${RED}partitioning done${RESET}"
  parted /dev/$DISK print

  # continue
  ct
}

step3()
{
  # init fs and luks
  echo -e "-- ${GREEN}STEP 3${RESET}"
  echo -e "-- making ${RED}fat32/btrfs and LUKS${RESET}"

  PART1="/dev/${DISK}1"
  PART2="/dev/${DISK}2"

  if [[ "$DISK" == nvme* ]]; then
    PART1="/dev/${DISK}p1"
    PART2="/dev/${DISK}p2"
  fi

  echo "-- your partitions ${RED}are right?${RESET}"
  echo "PART1=$PART1 PART2=$PART2"
  
  set +e
  while true; do
    cryptsetup luksFormat ${PART2} \
      --iter-time=2000 \
      --pbkdf=argon2id \
      --key-size=256 \
      --hash=sha256
    if [[ $? -eq 0 ]]; then
      break
    fi
  done

  while true; do
    cryptsetup luksOpen ${PART2} root
    if [[ $? -eq 0 ]]; then
      break
    fi
  done
  set -e
  
  mkfs.btrfs /dev/mapper/root
  mount /dev/mapper/root /mnt
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@snapshots
  umount /mnt
  mount -o compress=zstd3,subvol=@ /dev/mapper/root /mnt
  mkdir /mnt/{boot,.snapshots}
  mount -o compress=zstd3,subvol=@snapshots /dev/mapper/root /mnt/.snapshots
  
  mkfs.vfat -F 32 ${PART1}
  mount ${PART1}

  # continue
  ct
}

# run
reset_steps

step0

step1

step2

step3
