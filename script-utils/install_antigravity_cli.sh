#!/usr/bin/env bash
set -euo pipefail

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required."
  exit 1
fi

curl -fsSL https://antigravity.google/cli/install.sh | bash

echo "Antigravity CLI installed successfully. Run 'agy' to authenticate and get started."
