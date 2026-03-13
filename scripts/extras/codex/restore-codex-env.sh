#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../../lib/common.sh
source "${SCRIPT_DIR}/../../../lib/common.sh"

load_lab_config
default_scratch_paths

CODEX_HOME_DIR="${SCRATCH_MOUNT}/.codex"
NPM_GLOBAL_PREFIX="${SCRATCH_MOUNT}/npm-global"

echo "======================================"
echo "Daily setup: Codex environment restore"
echo "======================================"

if ! mountpoint -q "$SCRATCH_MOUNT"; then
  die "${SCRATCH_MOUNT} is not mounted. Run scripts/instance/mount-scratch-ebs.sh first."
fi

if [[ ! -f "$SHARED_BASHRC_PATH" ]]; then
  die "${SHARED_BASHRC_PATH} not found. Run scripts/extras/codex/setup-persistence.sh once first."
fi

ensure_bashrc_sources_shared

mkdir -p "$CODEX_HOME_DIR"

if [[ -e "$HOME/.codex" && ! -L "$HOME/.codex" ]]; then
  echo "[WARN] ~/.codex exists and is not a symlink. Leaving it unchanged."
else
  ln -sfn "$CODEX_HOME_DIR" "$HOME/.codex"
fi

# Warn if npm global prefix drifts from the scratch install path.
if command -v npm >/dev/null 2>&1; then
  CURRENT_PREFIX="$(npm prefix -g 2>/dev/null || true)"
  if [[ -n "$CURRENT_PREFIX" && "$CURRENT_PREFIX" != "$NPM_GLOBAL_PREFIX" ]]; then
    echo "[WARN] npm global prefix is $CURRENT_PREFIX"
    echo "[WARN] Expected: $NPM_GLOBAL_PREFIX"
    echo "[WARN] Codex may update into a different location."
  fi
fi

echo
echo "[OK] Codex environment is wired to EBS."
echo "Run: source ~/.bashrc"
echo "Then check: codex --version"
