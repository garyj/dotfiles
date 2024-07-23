#!/usr/bin/env bash

# Install CUDA by adding it to sources.list.d rather than doing manual donwloads
# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Debian&target_version=12&target_type=deb_network
set -eufo pipefail

# Create a temporary directory and ensure its cleanup
temp_dir=$(mktemp -d)
trap 'rm -rf -- "$temp_dir"' EXIT
cd "$temp_dir"

wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo add-apt-repository contrib
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-3
