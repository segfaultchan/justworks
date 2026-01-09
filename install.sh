#!/bin/bash

STATE_PATH='./install.state'
CURRENT_STEP=0
STEP=0

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

check-step()
{
  # checking step
  if [[ ! -f "$STATE_PATH" ]]; then
    touch "$STATE_PATH"
  fi

  CURRENT_STEP="$(<"$STATE_PATH")"
  echo -e "-- starting from ${RED}${CURRENT_STEP} step${RESET}"
}

step0()
{
  STEP=0
  # skip step check
  if [[ $CURRENT_STEP -gt $STEP ]]; then
    return
  fi
  # checking internet connection
  echo $STEP > "$STATE_PATH"

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
  STEP=1
  # skip step check
  if [[ $CURRENT_STEP -gt $STEP ]]; then
    return
  fi
  # break point to step1
  echo $STEP > $STATE_PATH

  echo -e "-- ${GREEN}STEP 1${RESET}"
  cd "$SCRIPT_DIR"
  figlet -t -c -f ./share/figlet/Delta\ Corps\ Priest\ 1.flf $NAME | lolcat
  echo ""
  echo ""
  echo ""
  echo ""
  # install dependencies
  xi parted

  # continue
  ct
}

step2()
{
  STEP=2
  # skip step check
  if [[ $CURRENT_STEP -gt $STEP ]]; then
    return
  fi
  # break point to step2
  echo $STEP > $STATE_PATH

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
  STEP=3
  # skip step check
  if [[ $CURRENT_STEP -gt $STEP ]]; then
    return
  fi
  # break point to step3
  echo $STEP > $STATE_PATH

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
  
  while true; do
    set +e
    cryptsetup luksFormat ${PART2} \
      --iter-time=2000 \
      --pbkdf=argon2id \
      --key-size=256 \
      --hash=sha256

    cryptsetup luksOpen ${PART2} root
    if [[ $? -eq 0 ]]; then
      break
    fi
    break
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
check-step

step0

step1

step2

step3
