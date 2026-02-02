#!/usr/bin/env bash
set -e

SCRATCH_ROOT=/home/ubuntu/scratch
DOCKER_ROOT=${SCRATCH_ROOT}/docker

echo
echo "========================================"
echo "Phase 3: Configure Docker paths (GPU AMI)"
echo "========================================"
echo

# --------------------------------------------------
# 0. Sanity checks
# --------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker not found."
  echo "This script assumes a GPU AMI with Docker preinstalled."
  exit 1
fi

if [[ ! -d "${SCRATCH_ROOT}" ]]; then
  echo "ERROR: ${SCRATCH_ROOT} does not exist."
  echo "Did you run Phase 2-b?"
  exit 1
fi

echo "Docker version:"
docker --version
echo

# --------------------------------------------------
# 1. Configure Docker data-root
# --------------------------------------------------
echo "Configuring Docker data-root:"
echo "  ${DOCKER_ROOT}"

sudo mkdir -p "${DOCKER_ROOT}"
sudo chown root:root "${DOCKER_ROOT}"

sudo mkdir -p /etc/docker

if [[ -f /etc/docker/daemon.json ]]; then
  echo "WARNING: /etc/docker/daemon.json already exists."
  echo "Please review it manually if you customized Docker before."
fi

cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "data-root": "${DOCKER_ROOT}"
}
EOF

# --------------------------------------------------
# 2. Restart Docker
# --------------------------------------------------
echo "Restarting Docker..."
sudo systemctl restart docker

# --------------------------------------------------
# 3. Verify
# --------------------------------------------------
echo
echo "Docker root directory:"
docker info --format '{{.DockerRootDir}}'

echo
echo "========================================"
echo "PHASE 3 COMPLETE"
echo "Docker now uses persistent EBS:"
echo "  ${DOCKER_ROOT}"
echo
echo "Next:"
echo "  Verify GPU Docker with:"
echo "    docker run --rm --gpus all \\"
echo "      nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi"
echo "========================================"
