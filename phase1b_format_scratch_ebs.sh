#!/usr/bin/env bash
set -e

# ========= CONFIG =========
DEVICE=/dev/nvme1n1   # scratch EBS (not root!)
FS_TYPE=ext4
# ==========================

echo "=== Listing block devices ==="
lsblk

echo
echo "!!! WARNING !!!"
echo "This will FORMAT ${DEVICE}"
echo "ALL DATA WILL BE LOST"
echo
read -p "Type YES to continue: " CONFIRM

if [[ "${CONFIRM}" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

echo "=== Formatting scratch EBS ==="
sudo mkfs.${FS_TYPE} ${DEVICE}

echo
echo "======================================"
echo "PHASE 1-B DONE"
echo "Scratch EBS now has filesystem:"
echo "  ${FS_TYPE}"
echo "======================================"
echo
echo "You can now:"
echo "  - detach the volume"
echo "  - terminate this instance"
