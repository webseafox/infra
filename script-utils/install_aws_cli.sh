#!/usr/bin/env bash
set -euo pipefail

if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
  echo "curl and unzip are required."
  exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

ARCH=$(uname -m)
case "$ARCH" in
  x86_64) AWS_ARCH="x86_64" ;;
  aarch64|arm64) AWS_ARCH="aarch64" ;;
  *)
    echo "Unsupported architecture for AWS CLI: $ARCH"
    exit 1
    ;;
esac

curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "$TMP_DIR/awscliv2.zip"
unzip -q "$TMP_DIR/awscliv2.zip" -d "$TMP_DIR"

sudo "$TMP_DIR/aws/install" --update

echo "AWS CLI installed successfully."
