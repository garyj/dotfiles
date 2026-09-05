#!/bin/bash
# Absent on machines without the ~/.agents external, so nothing to link there.
set -euo pipefail
install="$HOME/.agents/scripts/install"
[ -x "$install" ] || exit 0
"$install" --bridge "$HOME/.local/share/agent-skills"
