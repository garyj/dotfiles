#!/usr/bin/env bash
# gh-token <org>  ->  prints a short-lived GitHub App installation token for <org>.
# Reads the "Agent Lara" App creds from 1Password via OP_SERVICE_ACCOUNT_TOKEN
# (set by the agent launcher). The App private key never lands on disk. Tokens are
# cached per-org in tmpfs and reused for ~50 min (they live 60), shared by the git
# credential helper and the gh shim.
set -euo pipefail

ORG="${1:?usage: gh-token <org>}"

cache_dir="${XDG_RUNTIME_DIR:-/tmp}/lara-gh"
cache="$cache_dir/$ORG"
if [ -f "$cache" ] && [ "$(( $(date +%s) - $(stat -c %Y "$cache") ))" -lt 3000 ]; then
  cat "$cache"; exit 0
fi

ITEM='op://AGLara/Lara GitHub App'
APP_ID="$(op read "$ITEM/app_id")"
KEY="$(op read "$ITEM/private_key")"

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

# JWT (RS256), valid <=10 min, signed by the App key.
now=$(date +%s)
hdr='{"alg":"RS256","typ":"JWT"}'
pay=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$((now-60))" "$((now+540))" "$APP_ID")
si="$(printf %s "$hdr" | b64url).$(printf %s "$pay" | b64url)"
sig=$(printf %s "$si" | openssl dgst -sha256 -sign <(printf '%s' "$KEY") -binary | b64url)
jwt="$si.$sig"

api() { curl -sf -H "Authorization: Bearer $jwt" -H "Accept: application/vnd.github+json" \
             -H "X-GitHub-Api-Version: 2022-11-28" "$@"; }

id=$(api https://api.github.com/app/installations | jq -r --arg o "$ORG" '.[]|select(.account.login==$o)|.id')
[ -n "$id" ] || { echo "Agent Lara App not installed on '$ORG'" >&2; exit 1; }

token=$(api -X POST "https://api.github.com/app/installations/$id/access_tokens" | jq -r '.token')
mkdir -p "$cache_dir"; chmod 700 "$cache_dir"
(umask 077; printf '%s' "$token" > "$cache")
printf '%s\n' "$token"
