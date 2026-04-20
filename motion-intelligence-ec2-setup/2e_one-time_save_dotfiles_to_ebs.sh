#!/usr/bin/env bash
set -euo pipefail

SCRATCH="$HOME/scratch"
DOTFILES="$SCRATCH/dotfiles"
SSH_DST="$DOTFILES/ssh"

echo "======================================"
echo "Saving dotfiles to persistent EBS"
echo "======================================"

mkdir -p "$DOTFILES"
mkdir -p "$SSH_DST"

###############################################################################
# Save .bashrc
###############################################################################
echo "[INFO] Saving ~/.bashrc"
cp ~/.bashrc "$DOTFILES/bashrc"
chmod 644 "$DOTFILES/bashrc"

###############################################################################
# Save SSH private key (Option A)
###############################################################################
if [[ -f ~/.ssh/id_ed25519 ]]; then
  echo "[INFO] Saving SSH private key (id_ed25519)"
  cp ~/.ssh/id_ed25519 "$SSH_DST/id_ed25519"
  chmod 600 "$SSH_DST/id_ed25519"
else
  echo "[WARN] ~/.ssh/id_ed25519 not found — skipping"
fi

if [[ -f ~/.ssh/id_ed25519.pub ]]; then
  cp ~/.ssh/id_ed25519.pub "$SSH_DST/id_ed25519.pub"
  chmod 644 "$SSH_DST/id_ed25519.pub"
fi

###############################################################################
# Save TeX Live environment
###############################################################################
if [[ -f ~/.texlive-env ]]; then
  echo "[INFO] Saving ~/.texlive-env"
  cp ~/.texlive-env "$DOTFILES/texlive-env"
  chmod 644 "$DOTFILES/texlive-env"
else
  echo "[WARN] ~/.texlive-env not found — skipping"
fi

###############################################################################
# Summary
###############################################################################
echo
echo "======================================"
echo "DONE"
echo "Saved:"
echo "  - bashrc        -> $DOTFILES/bashrc"
echo "  - SSH key       -> $SSH_DST/id_ed25519"
echo "  - texlive-env   -> $DOTFILES/texlive-env"
echo
echo "NOTE:"
echo "  Private key is stored on EBS."
echo "  Ensure EBS access is restricted."
echo "======================================"
