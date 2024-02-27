#!/bin/bash

# This script is used to install the Digital Ocean CLI

set -eufo pipefail

VERSION=1.104.0

temp_dir=$(mktemp -d)
trap 'rm -rf -- "$temp_dir"' EXIT
cd "$temp_dir"


wget https://github.com/digitalocean/doctl/releases/download/v$VERSION/doctl-$VERSION-linux-amd64.tar.gz
tar xf ./doctl-$VERSION-linux-amd64.tar.gz
sudo mv ./doctl /usr/local/bin

cd -
