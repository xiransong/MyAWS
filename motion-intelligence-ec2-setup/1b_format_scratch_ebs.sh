#!/usr/bin/env bash
set -e

FS_TYPE=ext4

echo
echo "========================================"
echo "Phase 1-b: FORMAT persistent EBS volume"
echo "========================================"
echo

# --------------------------------------------------
# 1. User provides volume ID
# --------------------------------------------------
echo "Enter the EBS Volume ID to FORMAT (e.g. vol-0abc123...):"
read -r VOLUME_ID

if [[ -z "${VOLUME_ID}" ]]; then
  echo "ERROR: Volume ID cannot be empty."
  exit 1
fi

VOLUME_ID_NODASH=${VOLUME_ID//-/}

echo
echo "Resolving Linux device for volume ${VOLUME_ID} ..."

# --------------------------------------------------
# 2. Resolve device via /dev/disk/by-id
# --------------------------------------------------
MATCHES=$(ls /dev/disk/by-id/ 2>/dev/null | \
  grep "nvme-Amazon_Elastic_Block_Store_${VOLUME_ID_NODASH}" || true)

if [[ -z "${MATCHES}" ]]; then
  echo "ERROR: No device found for volume ${VOLUME_ID}"
  echo "Is the volume attached to this instance?"
  exit 1
fi

# Prefer unsuffixed name, fallback otherwise
BY_ID_LINK=$(echo "${MATCHES}" | grep -v '_[0-9]\+$' | head -n 1)
if [[ -z "${BY_ID_LINK}" ]]; then
  BY_ID_LINK=$(echo "${MATCHES}" | head -n 1)
fi

REAL_DEVICE=$(readlink -f "/dev/disk/by-id/${BY_ID_LINK}")

# --------------------------------------------------
# 3. DRY RUN — explicit confirmation
# --------------------------------------------------
echo
echo "========================================"
echo "DANGEROUS OPERATION — DRY RUN"
echo
echo "Volume ID     : ${VOLUME_ID}"
echo "By-id link    : ${BY_ID_LINK}"
echo "Block device  : ${REAL_DEVICE}"
echo "Filesystem    : ${FS_TYPE}"
echo
echo "Planned action:"
echo "  - mkfs.${FS_TYPE} ${REAL_DEVICE}"
echo
echo "ALL EXISTING DATA ON THIS DEVICE WILL BE LOST."
echo "========================================"
read -p "Type YES to FORMAT this volume: " CONFIRM

if [[ "${CONFIRM}" != "YES" ]]; then
  echo "Aborted by user."
  exit 1
fi

# --------------------------------------------------
# 4. FORMAT
# --------------------------------------------------
echo
echo "=== Formatting volume ${VOLUME_ID} ==="
sudo mkfs.${FS_TYPE} "${REAL_DEVICE}"

# --------------------------------------------------
# Done
# --------------------------------------------------
echo
echo "========================================"
echo "PHASE 1-B COMPLETE"
echo "Volume ${VOLUME_ID} formatted as ${FS_TYPE}"
echo
echo "Next steps:"
echo "  - detach the volume"
echo "  - terminate this instance"
echo "  - NEVER format this volume again"
echo "========================================"
