#!/usr/bin/env bash

# Ref: https://github.com/twpayne/dotfiles/blob/master/home/.chezmoiscripts/linux/run_onchange_after_max-user-watches.sh.tmpl

if ! grep -qF "fs.inotify.max_user_watches = 524288" /etc/sysctl.conf; then
	echo fs.inotify.max_user_watches = 524288 | sudo tee -a /etc/sysctl.conf
	sudo sysctl -p
fi
