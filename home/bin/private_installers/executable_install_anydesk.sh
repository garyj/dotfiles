#!/usr/bin/env bash
curl -fSsL https://keys.anydesk.com/repos/DEB-GPG-KEY |
  gpg --dearmor | sudo tee /usr/share/keyrings/anydesk.gpg >/dev/null

echo 'deb [signed-by=/usr/share/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main' |
  sudo tee /etc/apt/sources.list.d/anydesk.list

sudo apt-get update && sudo apt-get install -y anydesk
