# shellcheck shell=bash
#
# Sourced by a per-agent entry script (lara, ...) once it has set the AGENT_*
# contract below. Rewrites this process's environment so every git, gh and op call
# downstream acts as that agent, then the caller exec's into the real command.
#
# Contract, all required:
#   AGENT_NAME        short name, used in messages and the token cache path
#   AGENT_OP_ITEM     op:// path to the GitHub App item (app_id + private_key fields)
#   AGENT_STATE_DIR   machine-local dir holding `token` and gh's config
#   AGENT_GIT_NAME    commit author name
#   AGENT_GIT_EMAIL   commit author email

: "${AGENT_NAME:?identity.sh: AGENT_NAME not set}"
: "${AGENT_OP_ITEM:?identity.sh: AGENT_OP_ITEM not set}"
: "${AGENT_STATE_DIR:?identity.sh: AGENT_STATE_DIR not set}"
: "${AGENT_GIT_NAME:?identity.sh: AGENT_GIT_NAME not set}"
: "${AGENT_GIT_EMAIL:?identity.sh: AGENT_GIT_EMAIL not set}"

_agent_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_agent_token="$AGENT_STATE_DIR/token"

# An explicit `lara ...` that quietly ran as you would be worse than an error.
if [ ! -r "$_agent_token" ]; then
  echo "$AGENT_NAME: not provisioned on this box ($_agent_token missing)" >&2
  echo "$AGENT_NAME: see ~/bin/agents/SETUP.md" >&2
  exit 1
fi

unset SSH_AUTH_SOCK GITHUB_TOKEN GH_TOKEN     # no 1Password SSH agent, no personal gh token
OP_SERVICE_ACCOUNT_TOKEN="$(cat "$_agent_token")"
export OP_SERVICE_ACCOUNT_TOKEN               # op -> the agent's vault only, no desktop prompt
export GH_CONFIG_DIR="$AGENT_STATE_DIR/gh"    # gh state kept away from yours
export PATH="$_agent_lib/shim:$PATH"          # gh shim -> scoped App token

# Commits are unsigned: the only signing key on this box is yours, and signing with
# it would claim the bot's work as yours. Tags carry their own switch because
# commit.gpgsign does not cover annotated tags.
export GIT_CONFIG_COUNT=7
export GIT_CONFIG_KEY_0=user.name              GIT_CONFIG_VALUE_0="$AGENT_GIT_NAME"
export GIT_CONFIG_KEY_1=user.email             GIT_CONFIG_VALUE_1="$AGENT_GIT_EMAIL"
export GIT_CONFIG_KEY_2=commit.gpgsign         GIT_CONFIG_VALUE_2=false
export GIT_CONFIG_KEY_3=tag.forceSignAnnotated GIT_CONFIG_VALUE_3=false
export GIT_CONFIG_KEY_4="credential.https://github.com.helper"      GIT_CONFIG_VALUE_4=""
export GIT_CONFIG_KEY_5="credential.https://github.com.helper"      GIT_CONFIG_VALUE_5="$_agent_lib/git-credential.sh"
export GIT_CONFIG_KEY_6="credential.https://github.com.useHttpPath" GIT_CONFIG_VALUE_6=true
