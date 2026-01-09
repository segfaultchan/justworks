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

ct() {
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

greeting() {
  cd "$SCRIPT_DIR"
  figlet -t -c -f ./share/figlet/Delta\ Corps\ Priest\ 1.flf $NAME | lolcat
  echo ""
  echo ""
  echo ""
  echo ""
  # install dependencies
  xi parted
}

network() {
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
  parted -s /dev/$DISK set 2 
  parted -s /dev/$DISK align-check optimal 1
  parted -s /dev/$DISK print

}

# run
greeting
ct

partitioning
ct
