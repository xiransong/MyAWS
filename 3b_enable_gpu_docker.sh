#!/usr/bin/env bash
set -e

echo
echo "========================================"
echo "Phase 3-b: Enable GPU support for Docker"
echo "========================================"
echo

# --------------------------------------------------
# 0. Sanity checks
# --------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker not found."
  echo "Did you run Phase 3-a?"
  exit 1
fi

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: NVIDIA driver not found."
  echo "Are you on a GPU instance with a GPU AMI?"
  exit 1
fi

echo "Docker found."
echo "NVIDIA driver found:"
nvidia-smi | head -n 5
echo

# --------------------------------------------------
# 1. Install NVIDIA Container Toolkit
# --------------------------------------------------
echo "Installing NVIDIA Container Toolkit..."

sudo apt-get update
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg

sudo install -m 0755 -d /usr/share/keyrings

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit.gpg

curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# --------------------------------------------------
# 2. Configure Docker to use NVIDIA runtime
# --------------------------------------------------
echo "Configuring Docker NVIDIA runtime..."
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# --------------------------------------------------
# Done
# --------------------------------------------------
echo
echo "========================================"
echo "PHASE 3-B COMPLETE"
echo
echo "IMPORTANT:"
echo "  Log out and log back in (or reboot) so docker group applies."
echo
echo "Verify GPU with:"
echo "  docker run --rm --gpus all \\"
echo "    nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi"
echo "========================================"
