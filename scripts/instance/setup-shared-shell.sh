#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

load_lab_config
default_scratch_paths

if ! mountpoint -q "$SCRATCH_MOUNT"; then
  die "${SCRATCH_MOUNT} is not mounted. Run scripts/instance/mount-scratch-ebs.sh first."
fi

mkdir -p "$(dirname "$SHARED_BASHRC_PATH")" "${SCRATCH_MOUNT}/bin"
touch "$SHARED_BASHRC_PATH"

append_managed_block "$SHARED_BASHRC_PATH" "myaws shared shell defaults" "if [ -d \"${SCRATCH_MOUNT}/bin\" ]; then
  export PATH=\"${SCRATCH_MOUNT}/bin:\$PATH\"
fi"

echo
echo "[OK] Shared shell config is ready at:"
echo "  ${SHARED_BASHRC_PATH}"
echo
echo "Next:"
echo "  bash scripts/instance/bootstrap-user-shell.sh"
