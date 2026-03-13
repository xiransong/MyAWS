#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

load_lab_config
default_scratch_paths

if [[ ! -f "$SHARED_BASHRC_PATH" ]]; then
  die "${SHARED_BASHRC_PATH} not found. Run scripts/instance/setup-shared-shell.sh first."
fi

ensure_bashrc_sources_shared

echo
echo "[OK] ${HOME}/.bashrc now sources the shared shell config."
echo "Run: source ~/.bashrc"
