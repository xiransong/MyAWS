#!/usr/bin/env bash
set -euo pipefail

SCRATCH="$HOME/scratch"
DOTFILES="$SCRATCH/dotfiles"
SSH_SRC="$DOTFILES/ssh"

echo "======================================"
echo "Restoring dotfiles from persistent EBS"
echo "======================================"

###############################################################################
# Restore .bashrc
###############################################################################
if [[ -f "$DOTFILES/bashrc" ]]; then
  echo "[INFO] Restoring ~/.bashrc"
  cp "$DOTFILES/bashrc" ~/.bashrc
  chmod 644 ~/.bashrc
else
  echo "[WARN] No bashrc found in $DOTFILES"
fi

###############################################################################
# Restore SSH key
###############################################################################
mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [[ -f "$SSH_SRC/id_ed25519" ]]; then
  echo "[INFO] Restoring SSH private key"
  cp "$SSH_SRC/id_ed25519" ~/.ssh/id_ed25519
  chmod 600 ~/.ssh/id_ed25519
else
  echo "[WARN] No SSH private key found in $SSH_SRC"
fi

if [[ -f "$SSH_SRC/id_ed25519.pub" ]]; then
  cp "$SSH_SRC/id_ed25519.pub" ~/.ssh/id_ed25519.pub
  chmod 644 ~/.ssh/id_ed25519.pub
fi

###############################################################################
# Final message
###############################################################################
echo
echo "======================================"
echo "DONE"
echo
echo "Next steps:"
echo "  source ~/.bashrc"
echo "  ssh -T git@github.com"
echo "======================================"
