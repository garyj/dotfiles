# Aliases written by `op plugin init <tool>`; each routes a CLI through 1Password
# (wrangler -> `op plugin run -- wrangler`) so no token lands on disk.
# Only a bare `wrangler` hits the alias; `npm run deploy` / `npx wrangler` bypass it.
if [ -f "$HOME/.config/op/plugins.sh" ]; then
  source "$HOME/.config/op/plugins.sh"
fi

# Exports the API keys from the 1Password "Misc Credentials" item into this shell.
creds() {
  [ -f "$HOME/.creds/misc_api_creds" ] || { echo "creds: ~/.creds/misc_api_creds missing" >&2; return 1; }
  . "$HOME/.creds/misc_api_creds"
}
