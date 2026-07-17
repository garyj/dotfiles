#!/usr/bin/env bash
# Copies the selected path(s) to the clipboard, one per line for multi-select.
if [ "$#" -eq 1 ]; then
    printf '%s' "$1"
else
    printf '%s\n' "$@"
fi | xclip -selection clipboard
