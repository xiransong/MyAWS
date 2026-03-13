#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../../lib/common.sh
source "${SCRIPT_DIR}/../../../lib/common.sh"

load_lab_config
default_scratch_paths

TOOLS_ROOT="${SCRATCH_MOUNT}/tools/node"
VERSIONS_DIR="$TOOLS_ROOT/versions"
CURRENT_LINK="$TOOLS_ROOT/current"
SCRATCH_BIN="${SCRATCH_MOUNT}/bin"

echo "======================================"
echo "One-time install: Node.js on EBS"
echo "======================================"

if ! mountpoint -q "$SCRATCH_MOUNT"; then
  die "${SCRATCH_MOUNT} is not mounted. Run scripts/instance/mount-scratch-ebs.sh first."
fi

require_command curl
require_command python3

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) NODE_ARCH="x64" ;;
  aarch64|arm64) NODE_ARCH="arm64" ;;
  *)
    echo "[ERROR] Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

mkdir -p "$VERSIONS_DIR" "$SCRATCH_BIN"

if [[ -x "$CURRENT_LINK/bin/node" ]]; then
  echo "[INFO] Node.js already installed at $CURRENT_LINK"
  "$CURRENT_LINK/bin/node" -v
  "$CURRENT_LINK/bin/npm" -v
  exit 0
fi

if [[ -z "${NODE_VERSION:-}" ]]; then
  echo "[INFO] Resolving latest LTS Node.js version..."
  NODE_VERSION="$(
    curl -fsSL https://nodejs.org/dist/index.json | python3 -c '
import json,sys
data=json.load(sys.stdin)
for item in data:
    if item.get("lts"):
        print(item["version"])
        break
'
  )"
fi

if [[ -z "${NODE_VERSION}" ]]; then
  echo "[ERROR] Could not determine Node.js version."
  exit 1
fi

echo "[INFO] Installing Node.js ${NODE_VERSION} for linux-${NODE_ARCH}"

TARBALL="node-${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"
URL="https://nodejs.org/dist/${NODE_VERSION}/${TARBALL}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fL "$URL" -o "$TMP_DIR/$TARBALL"
tar -xJf "$TMP_DIR/$TARBALL" -C "$TMP_DIR"

EXTRACTED_DIR="$TMP_DIR/node-${NODE_VERSION}-linux-${NODE_ARCH}"
TARGET_DIR="$VERSIONS_DIR/${NODE_VERSION}"

if [[ ! -d "$EXTRACTED_DIR" ]]; then
  echo "[ERROR] Extracted directory not found: $EXTRACTED_DIR"
  exit 1
fi

rm -rf "$TARGET_DIR"
mv "$EXTRACTED_DIR" "$TARGET_DIR"
ln -sfn "$TARGET_DIR" "$CURRENT_LINK"

ln -sfn "$CURRENT_LINK/bin/node" "$SCRATCH_BIN/node"
ln -sfn "$CURRENT_LINK/bin/npm" "$SCRATCH_BIN/npm"
ln -sfn "$CURRENT_LINK/bin/npx" "$SCRATCH_BIN/npx"
if [[ -x "$CURRENT_LINK/bin/corepack" ]]; then
  ln -sfn "$CURRENT_LINK/bin/corepack" "$SCRATCH_BIN/corepack"
fi

echo
echo "[OK] Node.js installed on EBS."
echo "Version: $("$CURRENT_LINK/bin/node" -v)"
echo "npm: $("$CURRENT_LINK/bin/npm" -v)"
echo "Path: $CURRENT_LINK"
echo "Run: source ~/.bashrc"
