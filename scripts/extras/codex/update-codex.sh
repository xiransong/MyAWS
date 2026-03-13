#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo "Update: Codex CLI"
echo "======================================"

CODEX_FORCE_INSTALL=1 bash "${SCRIPT_DIR}/install-codex.sh"

echo
echo "[OK] Codex CLI update complete."
echo "Run: source ~/.bashrc"
echo "Then check: codex --version"
