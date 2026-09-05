# Aliases written by `op plugin init <tool>`; each routes a CLI through 1Password
# (wrangler -> `op plugin run -- wrangler`) so no token lands on disk.
# Only a bare `wrangler` hits the alias; `npm run deploy` / `npx wrangler` bypass it.
if [ -f "$HOME/.config/op/plugins.sh" ]; then
  source "$HOME/.config/op/plugins.sh"
fi
