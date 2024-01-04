#!/bin/bash

set -eufo pipefail

#MongoDB
# https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-os-x/
xcode-select --install || true # in case we have alredady instaalled xcode command line tools we can ignore the error https://stackoverflow.com/questions/11231937/bash-ignoring-error-for-a-particular-command
brew tap mongodb/brew
brew update
brew install mongodb-community@7.0

# Install MongoDB Compass
brew install --cask mongodb-compass
