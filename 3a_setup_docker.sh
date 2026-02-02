#!/usr/bin/env bash
set -e

SCRATCH_ROOT=/home/ubuntu/scratch
DOCKER_ROOT=${SCRATCH_ROOT}/docker

echo
echo "========================================"
echo "Phase 3-a: Install Docker (OPTIONAL)"
echo "========================================"
echo

# --------------------------------------------------
# 0. Sanity check
# --------------------------------------------------
if [[ ! -d "${SCRATCH_ROOT}" ]]; then
  echo "ERROR: ${SCRATCH_ROOT} does not exist."
  echo "Did you run Phase 2-b?"
  exit 1
fi

# --------------------------------------------------
# 1. Install Docker
# --------------------------------------------------
echo "Installing Docker..."
sudo apt-get update
sudo apt-get install -y docker.io

# --------------------------------------------------
# 2. Configure Docker data-root
# --------------------------------------------------
echo "Configuring Docker data-root at:"
echo "  ${DOCKER_ROOT}"

sudo mkdir -p "${DOCKER_ROOT}"
sudo chown root:root "${DOCKER_ROOT}"

sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "data-root": "${DOCKER_ROOT}"
}
EOF

# --------------------------------------------------
# 3. Enable Docker + user access
# --------------------------------------------------
sudo systemctl enable docker
sudo systemctl restart docker

sudo usermod -aG docker ubuntu

# --------------------------------------------------
# Done
# --------------------------------------------------
echo
echo "========================================"
echo "PHASE 3-A COMPLETE"
echo
echo "Docker installed and configured."
echo "Docker data-root:"
echo "  ${DOCKER_ROOT}"
echo
echo "IMPORTANT:"
echo "  Log out and log back in for docker group to take effect."
echo
echo "Verify after re-login:"
echo "  docker info | grep 'Docker Root Dir'"
echo "========================================"
