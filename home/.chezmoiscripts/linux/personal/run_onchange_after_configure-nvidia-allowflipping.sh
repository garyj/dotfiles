#!/usr/bin/env bash

set -euo pipefail

[ -d /proc/driver/nvidia ] || exit 0

sudo tee /etc/X11/xorg.conf.d/20-nvidia-allowflipping.conf >/dev/null <<'EOF'
# With flipping on, each X server grab waits for the compositor's pending
# flip; GTK4 grabs ~150 times per window build, so a new ghostty window
# takes seconds.
Section "OutputClass"
    Identifier "nvidia-allowflipping"
    MatchDriver "nvidia-drm"
    Driver "nvidia"
    Option "AllowFlipping" "off"
EndSection
EOF
