#!/usr/bin/env bash
set -euo pipefail

echo "======================================"
echo "Update: Codex CLI"
echo "======================================"

CODEX_FORCE_INSTALL=1 bash 3b_one-time_install_codex_cli.sh

echo
echo "[OK] Codex CLI update complete."
echo "Run: source ~/.bashrc"
echo "Then check: codex --version"
