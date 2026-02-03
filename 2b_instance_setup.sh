#!/usr/bin/env bash
set -e

SCRATCH_MOUNT=/home/ubuntu/scratch
FS_TYPE=ext4

echo
echo "========================================"
echo "Phase 2-b: Mount persistent EBS workspace"
echo "========================================"
echo

# --------------------------------------------------
# 1. User provides volume ID
# --------------------------------------------------
echo "Enter the persistent EBS Volume ID (e.g. vol-0abc123...):"
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
FSTYPE=$(lsblk -no FSTYPE "${REAL_DEVICE}")

# --------------------------------------------------
# 3. Dry-run confirmation
# --------------------------------------------------
echo
echo "========================================"
echo "DRY RUN — PLEASE CONFIRM"
echo
echo "Volume ID     : ${VOLUME_ID}"
echo "By-id link    : ${BY_ID_LINK}"
echo "Block device  : ${REAL_DEVICE}"
echo "Filesystem    : ${FSTYPE:-<none>}"
echo "Mount point   : ${SCRATCH_MOUNT}"
echo
echo "Planned actions:"
echo "  - mkdir -p ${SCRATCH_MOUNT}"
echo "  - mount ${REAL_DEVICE} ${SCRATCH_MOUNT}"
echo "  - add entry to /etc/fstab (UUID-based)"
echo "  - chown ${SCRATCH_MOUNT} to ubuntu:ubuntu"
echo "  - create standard workspace directories"
echo
echo "NO formatting will be performed."
echo "========================================"
read -p "Type YES to proceed: " CONFIRM

if [[ "${CONFIRM}" != "YES" ]]; then
  echo "Aborted by user."
  exit 1
fi

# --------------------------------------------------
# 4. Mount and configure
# --------------------------------------------------
echo
echo "=== Mounting persistent EBS ==="
sudo mkdir -p "${SCRATCH_MOUNT}"

if ! mountpoint -q "${SCRATCH_MOUNT}"; then
  sudo mount "${REAL_DEVICE}" "${SCRATCH_MOUNT}"
else
  echo "Already mounted."
fi

UUID=$(sudo blkid -s UUID -o value "${REAL_DEVICE}")
grep -q "${UUID}" /etc/fstab || \
  echo "UUID=${UUID}  ${SCRATCH_MOUNT}  ${FS_TYPE}  defaults,nofail  0  2" | sudo tee -a /etc/fstab

echo
echo "=== Fixing ownership ==="
sudo chown ubuntu:ubuntu "${SCRATCH_MOUNT}"

echo
echo "=== Creating standard directories ==="
mkdir -p "${SCRATCH_MOUNT}"/{repos,data,outputs,transfer}

# --------------------------------------------------
# Done
# --------------------------------------------------
echo
echo "========================================"
echo "PHASE 2-B COMPLETE"
echo "Workspace ready at:"
echo "  ${SCRATCH_MOUNT}"
echo "========================================"
df -h | grep scratch || true
