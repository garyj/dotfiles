#!/usr/bin/env bash
VERSION=7.0
curl -fSsL https://pgp.mongodb.com/server-$VERSION.asc |
  gpg --dearmor | sudo tee /usr/share/keyrings/atlascli.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/atlascli.gpg arch=amd64,arm64] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/$VERSION multiverse" |
  sudo tee /etc/apt/sources.list.d/mongodb-org-$VERSION.list

sudo apt-get update && sudo apt-get install -y mongodb-atlas
