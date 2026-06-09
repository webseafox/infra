#!/usr/bin/env bash
set -euo pipefail

if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
  echo "curl and tar are required."
  exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

curl -L "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz" -o "$TMP_DIR/openshift-client-linux.tar.gz"
tar -xzf "$TMP_DIR/openshift-client-linux.tar.gz" -C "$TMP_DIR"

sudo install -m 0755 "$TMP_DIR/oc" /usr/local/bin/oc

if [[ -f "$TMP_DIR/kubectl" ]]; then
  sudo install -m 0755 "$TMP_DIR/kubectl" /usr/local/bin/kubectl
fi

echo "oc CLI installed successfully."
