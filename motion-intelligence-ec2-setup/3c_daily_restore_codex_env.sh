#!/usr/bin/env bash
set -euo pipefail

SCRATCH="$HOME/scratch"
SHARED_RC="$SCRATCH/dotfiles/bashrc_shared"
CODEX_HOME_DIR="$SCRATCH/.codex"
NPM_GLOBAL_PREFIX="$SCRATCH/npm-global"

echo "======================================"
echo "Daily setup: Codex environment restore"
echo "======================================"

if ! mountpoint -q "$SCRATCH"; then
  echo "[ERROR] $SCRATCH is not mounted."
  echo "Run 2b_instance_ebs_setup.sh first."
  exit 1
fi

if [[ ! -f "$SHARED_RC" ]]; then
  echo "[ERROR] $SHARED_RC not found."
  echo "Run 3a_one-time_setup_codex_persistence.sh once first."
  exit 1
fi

if ! grep -q "scratch bashrc_shared" "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" <<'EOF'

# >>> scratch bashrc_shared >>>
if [ -f "$HOME/scratch/dotfiles/bashrc_shared" ]; then
  source "$HOME/scratch/dotfiles/bashrc_shared"
fi
# <<< scratch bashrc_shared <<<
EOF
fi

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
