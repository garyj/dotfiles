#!/usr/bin/env bash

# Ghostty via mkasberg/ghostty-ubuntu — debian.griffo.io does not publish
# Mint packages, and mapping Mint codenames to Ubuntu suites there is fragile.
# Run in a tmpdir so any .deb artefacts don't land in the chezmoi script dir.

set -euo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"

