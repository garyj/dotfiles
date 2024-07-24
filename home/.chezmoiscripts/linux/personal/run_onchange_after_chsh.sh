#!/usr/bin/env bash

set -eufo pipefail

#  chsh -s /usr/bin/zsh
zsh_path="/bin/zsh"
sudo usermod --shell "${zsh_path}" '{{ .chezmoi.username }}'
