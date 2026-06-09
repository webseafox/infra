#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This script currently supports Debian/Ubuntu (apt-get) only."
  exit 1
fi

sudo apt-get update
sudo apt-get install -y vim curl

ARCH=$(uname -m)
case "$ARCH" in
  x86_64) VCLUSTER_ARCH="amd64" ;;
  aarch64|arm64) VCLUSTER_ARCH="arm64" ;;
  *)
    echo "Unsupported architecture for vcluster: $ARCH"
    exit 1
    ;;
esac

curl -L "https://github.com/loft-sh/vcluster/releases/latest/download/vcluster-linux-${VCLUSTER_ARCH}" -o /tmp/vcluster
sudo install -m 0755 /tmp/vcluster /usr/local/bin/vcluster
rm -f /tmp/vcluster

echo "vim and vcluster installed successfully."
