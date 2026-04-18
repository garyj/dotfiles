#!/usr/bin/env bash

set -euo pipefail

sudo tee /etc/sysctl.d/99-inotify.conf >/dev/null <<'EOF'
fs.inotify.max_user_instances = 1024
fs.inotify.max_user_watches = 8388608
EOF

sudo sysctl --system >/dev/null
