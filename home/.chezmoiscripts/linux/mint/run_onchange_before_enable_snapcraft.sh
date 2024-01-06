#!/bin/bash

# Enables Use of Snaps on Mint
# https://snapcraft.io/docs/installing-snap-on-linux-mint

sudo mv /etc/apt/preferences.d/nosnap.pref /tmp/
sudo apt update
sudo apt install snapd