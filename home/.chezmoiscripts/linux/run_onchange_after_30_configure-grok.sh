#!/usr/bin/env bash
set -euo pipefail

# grok (mise aqua:x.ai/cli/grok) checks for updates on launch by default, which
# would silently break the version pin in .chezmoidata.yaml. Seed the off
# switch once; the file stays user-owned after that (the grok TUI writes its
# own settings into it).
config="$HOME/.grok/config.toml"
if ! grep -qs '^auto_update' "$config"; then
  mkdir -p "$HOME/.grok"
  if grep -qs '^\[cli\]' "$config"; then
    sed -i '/^\[cli\]/a auto_update = false' "$config"
  else
    printf '[cli]\nauto_update = false\n' >> "$config"
  fi
fi
