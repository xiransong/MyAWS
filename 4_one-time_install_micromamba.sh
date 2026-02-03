#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "[INFO] Installing micromamba (non-interactive, reproducible)"
echo "============================================================"

###############################################################################
# Config
###############################################################################
MAMBA_ROOT_PREFIX="$HOME/scratch/micromamba"
BIN_DIR="$MAMBA_ROOT_PREFIX/bin"
MICROMAMBA_BIN="$BIN_DIR/micromamba"

###############################################################################
# Early exit if already installed
###############################################################################
if [ -x "$MICROMAMBA_BIN" ]; then
  echo "[INFO] micromamba already installed at:"
  echo "       $MICROMAMBA_BIN"
  "$MICROMAMBA_BIN" --version
  echo "============================================================"
  echo "✅ micromamba already present — skipping install"
  echo "============================================================"
  exit 0
fi

###############################################################################
# Prepare directories
###############################################################################
echo "[INFO] Creating micromamba directories..."
mkdir -p "$BIN_DIR"

###############################################################################
# Download micromamba (official static build)
###############################################################################
echo "[INFO] Downloading micromamba..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -L \
  https://micro.mamba.pm/api/micromamba/linux-64/latest \
  -o "$TMP_DIR/micromamba.tar.bz2"

###############################################################################
# Extract micromamba
###############################################################################
echo "[INFO] Extracting micromamba..."

tar -xjf "$TMP_DIR/micromamba.tar.bz2" -C "$TMP_DIR"

# The binary is located at bin/micromamba inside the tarball
if [ ! -f "$TMP_DIR/bin/micromamba" ]; then
  echo "[ERROR] micromamba binary not found after extraction!"
  exit 1
fi

mv "$TMP_DIR/bin/micromamba" "$MICROMAMBA_BIN"
chmod +x "$MICROMAMBA_BIN"

###############################################################################
# Initialize micromamba shell hook (bash only, no auto-activate)
###############################################################################
echo "[INFO] Initializing micromamba shell hook (bash)..."

"$MICROMAMBA_BIN" shell hook \
  --shell bash \
  --root-prefix "$MAMBA_ROOT_PREFIX" \
  > "$TMP_DIR/micromamba_hook.sh"

# Install hook idempotently
if ! grep -q "micromamba shell hook" "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" << EOF

# >>> micromamba shell hook >>>
export MAMBA_ROOT_PREFIX="$MAMBA_ROOT_PREFIX"
$(cat "$TMP_DIR/micromamba_hook.sh")
# <<< micromamba shell hook <<<
EOF
fi

###############################################################################
# Sanity check
###############################################################################
echo "[INFO] Verifying micromamba installation..."

export MAMBA_ROOT_PREFIX="$MAMBA_ROOT_PREFIX"
"$MICROMAMBA_BIN" --version

###############################################################################
# Final message
###############################################################################
echo "============================================================"
echo "✅ micromamba installed successfully"
echo "📍 Location: $MICROMAMBA_BIN"
echo "📦 Root prefix: $MAMBA_ROOT_PREFIX"
echo "➡️  Restart shell or run: source ~/.bashrc"
echo "============================================================"
