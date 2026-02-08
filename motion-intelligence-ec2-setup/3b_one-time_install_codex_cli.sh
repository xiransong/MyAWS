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

if ! command -v npm >/dev/null 2>&1; then
  echo "[ERROR] npm not found."
  echo "Install Node.js first, then re-run this script."
  exit 1
fi

CURRENT_CODEX_PATH=""
if command -v codex >/dev/null 2>&1; then
  CURRENT_CODEX_PATH="$(command -v codex)"
  echo "[INFO] codex currently in PATH: $CURRENT_CODEX_PATH"
  codex --version || true
  if [[ "${CODEX_FORCE_INSTALL:-}" != "1" && "$CURRENT_CODEX_PATH" == "$NPM_GLOBAL_PREFIX/bin/codex" ]]; then
    echo "[INFO] codex already installed under $NPM_GLOBAL_PREFIX."
    echo "Set CODEX_FORCE_INSTALL=1 to reinstall/update."
    exit 0
  fi
  if [[ "$CURRENT_CODEX_PATH" != "$NPM_GLOBAL_PREFIX/bin/codex" ]]; then
    echo "[WARN] codex is not installed under $NPM_GLOBAL_PREFIX."
    echo "[WARN] This script will install/update Codex into $NPM_GLOBAL_PREFIX."
  fi
fi

mkdir -p "$NPM_GLOBAL_PREFIX/bin"
echo "[INFO] Setting npm global prefix to: $NPM_GLOBAL_PREFIX"
npm config set prefix "$NPM_GLOBAL_PREFIX"

echo "[INFO] Installing package: $CODEX_NPM_PACKAGE"
npm install -g "$CODEX_NPM_PACKAGE"

if [ -x "$NPM_GLOBAL_PREFIX/bin/codex" ]; then
  ln -sf "$NPM_GLOBAL_PREFIX/bin/codex" "$SCRATCH/bin/codex"
fi

echo
echo "[OK] Installation complete."
echo "Run: source ~/.bashrc"
echo "Then check: codex --version"
