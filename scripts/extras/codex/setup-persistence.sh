#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../../lib/common.sh
source "${SCRIPT_DIR}/../../../lib/common.sh"

load_lab_config
default_scratch_paths

DOTFILES_DIR="${SCRATCH_MOUNT}/dotfiles"
CODEX_HOME_DIR="${SCRATCH_MOUNT}/.codex"
SCRATCH_BIN="${SCRATCH_MOUNT}/bin"
NPM_GLOBAL_PREFIX="${SCRATCH_MOUNT}/npm-global"

echo "======================================"
echo "One-time setup: Codex persistence"
echo "======================================"

if ! mountpoint -q "$SCRATCH_MOUNT"; then
  die "${SCRATCH_MOUNT} is not mounted. Run scripts/instance/mount-scratch-ebs.sh first."
fi

mkdir -p "$DOTFILES_DIR" "$CODEX_HOME_DIR" "$SCRATCH_BIN" "$NPM_GLOBAL_PREFIX/bin"

append_managed_block "$SHARED_BASHRC_PATH" "codex persistent setup" "export CODEX_HOME=\"${SCRATCH_MOUNT}/.codex\"
if [ -d \"${SCRATCH_MOUNT}/bin\" ]; then
  export PATH=\"${SCRATCH_MOUNT}/bin:\$PATH\"
fi
if [ -d \"${SCRATCH_MOUNT}/npm-global/bin\" ]; then
  export PATH=\"${SCRATCH_MOUNT}/npm-global/bin:\$PATH\"
fi"

ensure_bashrc_sources_shared

echo
echo "[OK] Persistent Codex directories ready:"
echo "  - $CODEX_HOME_DIR"
echo "  - $SCRATCH_BIN"
echo "  - $NPM_GLOBAL_PREFIX/bin"
echo "[OK] Shell wiring complete."
echo "Next:"
echo "  1) bash scripts/extras/codex/install-codex.sh"
echo "  2) source ~/.bashrc"
