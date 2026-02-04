#!/usr/bin/env bash
set -euo pipefail

SCRATCH="$HOME/scratch"
DOTFILES_DIR="$SCRATCH/dotfiles"
SHARED_RC="$DOTFILES_DIR/bashrc_shared"
CODEX_HOME_DIR="$SCRATCH/.codex"
SCRATCH_BIN="$SCRATCH/bin"
NPM_GLOBAL_PREFIX="$SCRATCH/npm-global"

echo "======================================"
echo "One-time setup: Codex persistence"
echo "======================================"

if ! mountpoint -q "$SCRATCH"; then
  echo "[ERROR] $SCRATCH is not mounted."
  echo "Run 2b_instance_ebs_setup.sh first."
  exit 1
fi

mkdir -p "$DOTFILES_DIR" "$CODEX_HOME_DIR" "$SCRATCH_BIN" "$NPM_GLOBAL_PREFIX/bin"

if [[ ! -f "$SHARED_RC" ]]; then
  touch "$SHARED_RC"
fi

if ! grep -q "codex persistent setup" "$SHARED_RC"; then
  cat >> "$SHARED_RC" <<'EOF'

# >>> codex persistent setup >>>
export CODEX_HOME="$HOME/scratch/.codex"
if [ -d "$HOME/scratch/bin" ]; then
  export PATH="$HOME/scratch/bin:$PATH"
fi
if [ -d "$HOME/scratch/npm-global/bin" ]; then
  export PATH="$HOME/scratch/npm-global/bin:$PATH"
fi
# <<< codex persistent setup <<<
EOF
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

echo
echo "[OK] Persistent Codex directories ready:"
echo "  - $CODEX_HOME_DIR"
echo "  - $SCRATCH_BIN"
echo "  - $NPM_GLOBAL_PREFIX/bin"
echo "[OK] Shell wiring complete."
echo "Next:"
echo "  1) bash 3b_one-time_install_codex_cli.sh"
echo "  2) source ~/.bashrc"
