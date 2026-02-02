#!/usr/bin/env bash
set -e

# ========= CONFIG =========
SCRATCH_DEVICE=/dev/nvme1n1      # persistent EBS
SCRATCH_MOUNT=/home/ubuntu/scratch

NVME_DEVICE=/dev/nvme2n1         # instance NVMe (may not exist)
NVME_MOUNT=/mnt/nvme

FS_TYPE=ext4
# ==========================

echo "=== [1/6] Block devices ==="
lsblk

# ---------------------------
# Persistent EBS
# ---------------------------
echo "=== [2/6] Mounting persistent scratch EBS ==="
sudo mkdir -p ${SCRATCH_MOUNT}

if ! mountpoint -q ${SCRATCH_MOUNT}; then
  sudo mount ${SCRATCH_DEVICE} ${SCRATCH_MOUNT}
else
  echo "Scratch already mounted."
fi

UUID=$(sudo blkid -s UUID -o value ${SCRATCH_DEVICE})
grep -q "${UUID}" /etc/fstab || \
  echo "UUID=${UUID}  ${SCRATCH_MOUNT}  ${FS_TYPE}  defaults,nofail  0  2" | sudo tee -a /etc/fstab

# ---------------------------
# Directory layout
# ---------------------------
echo "=== [3/6] Creating standard directories ==="
mkdir -p ${SCRATCH_MOUNT}/{repos,datasets,outputs,containers,docker,apptainer-cache}

# ---------------------------
# Docker setup (storage only)
# ---------------------------
echo "=== [4/6] Configuring Docker data-root ==="
sudo systemctl stop docker || true

sudo mkdir -p ${SCRATCH_MOUNT}/docker
sudo chown root:root ${SCRATCH_MOUNT}/docker

sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "data-root": "${SCRATCH_MOUNT}/docker"
}
EOF

sudo systemctl start docker || true

# ---------------------------
# Apptainer env
# ---------------------------
echo "=== [5/6] Configuring Apptainer cache ==="
grep -q APPTAINER_CACHEDIR ~/.bashrc || cat <<EOF >> ~/.bashrc
export APPTAINER_CACHEDIR=${SCRATCH_MOUNT}/apptainer-cache
export APPTAINER_TMPDIR=${SCRATCH_MOUNT}/apptainer-cache/tmp
EOF

# ---------------------------
# NVMe (optional)
# ---------------------------
echo "=== [6/6] Mounting NVMe SSD if present ==="
if lsblk | grep -q $(basename ${NVME_DEVICE}); then
  sudo mkdir -p ${NVME_MOUNT}
  sudo mount ${NVME_DEVICE} ${NVME_MOUNT} || true
else
  echo "No NVMe SSD detected — skipping."
fi

echo
echo "======================================"
echo "PHASE 2-B DONE"
echo "Persistent workspace:"
echo "  ${SCRATCH_MOUNT}"
echo "======================================"
df -h | grep -E "scratch|nvme" || true
