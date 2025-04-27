#!/usr/bin/env bash
op item get "SSH Key Builder" --vault "Personal" --format json | jq -r '.fields[] | select(.id=="notesPlain") | .value' | bash
