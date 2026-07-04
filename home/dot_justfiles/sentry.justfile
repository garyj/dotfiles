# ----------------------
# Sentry CLI recipes!
# ----------------------
#
# Binary is managed by mise (npm:sentry, pinned in .chezmoidata.yaml alongside
# the sentry-cli skill external); only auth/workflow recipes live here.

import "_common.justfile"

# see Sentry CLI usage
@help:
    command sentry --help

# authenticate with Sentry (interactive)
@auth:
    command sentry auth login

# authenticate with Sentry using token from 1Password
[script("bash")]
login:
    token=$(op read "op://Personal/Sentry/auth_token")
    command sentry auth login --token "$token"

# install zsh completion into oh-my-zsh dir (.zshrc is restored afterwards)
[script("bash")]
completions:
    command sentry cli setup --no-modify-path --no-agent-skills --quiet
    cp "$HOME/.local/share/zsh/site-functions/_sentry" "$HOME/.oh-my-zsh/completions/_sentry"
    chezmoi apply --force "$HOME/.zshrc"
    echo "✓ Installed _sentry to ~/.oh-my-zsh/completions/ (restart shell to pick up)"
