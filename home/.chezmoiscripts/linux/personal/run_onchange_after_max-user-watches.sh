#!/usr/bin/env bash

INSTANCES_VALUE="1024"
WATCHES_VALUE="8388608"

# Function to set or update sysctl value
set_sysctl_value() {
	local key="$1"
	local value="$2"
	local setting="$key = $value"

	if grep -q "^$key" /etc/sysctl.conf; then
		# Update existing value
		sudo sed -i "s/^$key.*/$setting/" /etc/sysctl.conf
	else
		# Add new value
		echo "$setting" | sudo tee -a /etc/sysctl.conf
	fi
}

set_sysctl_value "fs.inotify.max_user_instances" "$INSTANCES_VALUE"
set_sysctl_value "fs.inotify.max_user_watches" "$WATCHES_VALUE"

# Apply the changes
sudo sysctl -p
