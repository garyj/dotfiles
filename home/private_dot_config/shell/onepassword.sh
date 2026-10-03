# Exports the API keys from the 1Password "Misc Credentials" item into this shell.
creds() {
  [ -f "$HOME/.creds/misc_api_creds" ] || { echo "creds: ~/.creds/misc_api_creds missing" >&2; return 1; }
  . "$HOME/.creds/misc_api_creds"
}
