# Cloudflare account switcher, the twin of ~/bin/aws_exp.sh: `cf_exp <account>` exports
# wrangler's env auth plus CF_PROFILE for the starship prompt; `cf_exp off` clears them.
# An account is a 1Password item titled "Cloudflare - <Name>" with fields account_id and token (labels ignore case, spaces and underscores, so AccountID works).
# <Name> matches case-insensitively with spaces as dashes, so "Cloudflare - Agent Party" is agent-party.

_cf_norm() {
  tr '[:upper:]' '[:lower:]' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g; s/[[:space:]]+/-/g'
}

_cf_accounts() {
  op item list --format json | jq -c '.[] | select(.title | startswith("Cloudflare - "))
    | {id, vault: .vault.id, title, name: (.title | ltrimstr("Cloudflare - "))}'
}

cf_exp() {
  local name accounts match item
  name=$(printf '%s' "$*" | _cf_norm)
  if [ "$name" = off ]; then
    unset CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID CF_PROFILE
    return 0
  fi
  accounts=$(_cf_accounts) || return 1
  if [ -z "$name" ]; then
    echo "usage: cf_exp <account> | cf_exp off" >&2
    printf '%s\n' "$accounts" | jq -r .name | _cf_norm | sort | sed 's/^/  /' >&2
    return 1
  fi
  match=$(printf '%s\n' "$accounts" | while IFS= read -r a; do
    [ "$(printf '%s' "$a" | jq -r .name | _cf_norm)" = "$name" ] && printf '%s\n' "$a"
  done)
  case $(printf '%s' "$match" | grep -c .) in
    0) echo "cf_exp: no 1Password item 'Cloudflare - …' for '$name'; run cf_exp to list them" >&2; return 1 ;;
    1) ;;
    *) echo "cf_exp: more than one 1Password item matches '$name'" >&2; return 1 ;;
  esac
  item=$(op item get "$(printf '%s' "$match" | jq -r .id)" --vault "$(printf '%s' "$match" | jq -r .vault)" \
    --reveal --format json | jq -c '{
      account_id: [.fields[] | select(.label | ascii_downcase | gsub("[^a-z0-9]"; "") == "accountid") | .value][0],
      token: [.fields[] | select(.label | ascii_downcase | gsub("[^a-z0-9]"; "") == "token") | .value][0]}') || return 1
  if ! printf '%s' "$item" | jq -e '.account_id and .token' >/dev/null; then
    echo "cf_exp: $(printf '%s' "$match" | jq -r .title) needs account_id and token fields" >&2
    return 1
  fi
  CLOUDFLARE_API_TOKEN=$(printf '%s' "$item" | jq -r .token)
  CLOUDFLARE_ACCOUNT_ID=$(printf '%s' "$item" | jq -r .account_id)
  export CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID CF_PROFILE="$name"
  echo "CF_PROFILE=$CF_PROFILE"
  echo "CLOUDFLARE_ACCOUNT_ID=$CLOUDFLARE_ACCOUNT_ID"
}
