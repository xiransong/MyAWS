#!/usr/bin/env bash
set -euo pipefail

SCRATCH="$HOME/scratch"
NPM_GLOBAL_PREFIX="$SCRATCH/npm-global"
CODEX_NPM_PACKAGE="${CODEX_NPM_PACKAGE:-@openai/codex}"

echo "======================================"
echo "One-time install: Codex CLI"
echo "======================================"

if ! mountpoint -q "$SCRATCH"; then
  echo "[ERROR] $SCRATCH is not mounted."
  echo "Run 2b_instance_ebs_setup.sh first."
  exit 1
fi

if command -v codex >/dev/null 2>&1; then
  echo "[INFO] codex already available in PATH."
  codex --version || true
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "[ERROR] npm not found."
  echo "Install Node.js first, then re-run this script."
  exit 1
fi

echo "[INFO] Installing package: $CODEX_NPM_PACKAGE"
npm install -g --prefix "$NPM_GLOBAL_PREFIX" "$CODEX_NPM_PACKAGE"

if [ -x "$NPM_GLOBAL_PREFIX/bin/codex" ]; then
  ln -sf "$NPM_GLOBAL_PREFIX/bin/codex" "$SCRATCH/bin/codex"
fi

echo
echo "[OK] Installation complete."
echo "Run: source ~/.bashrc"
echo "Then check: codex --version"
