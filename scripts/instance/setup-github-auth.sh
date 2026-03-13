#!/usr/bin/env bash
set -euo pipefail

echo "======================================"
echo "GitHub authentication setup"
echo "======================================"
echo

if command -v gh >/dev/null 2>&1; then
  cat <<'EOF'
Recommended flow:
  gh auth login

This keeps credentials under the current user account instead of storing
private keys on the shared EBS volume by default.
EOF
  exit 0
fi

cat <<'EOF'
Recommended flow without GitHub CLI:
  1. Generate a fresh SSH key on this instance if needed:
       ssh-keygen -t ed25519 -C "your_email@example.com"
  2. Print the public key:
       cat ~/.ssh/id_ed25519.pub
  3. Add it to your GitHub account.

Avoid copying private SSH keys into shared storage unless you have a clear,
documented reason to do so.
EOF
