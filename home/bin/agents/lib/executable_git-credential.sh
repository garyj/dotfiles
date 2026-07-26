#!/usr/bin/env bash
# git credential helper: hand git a GitHub App installation token scoped to the
# repo's org. Wired in by identity.sh with
#   credential.https://github.com.useHttpPath = true
# so the org arrives in $path. Token caching lives in gh-token.sh. Only `get`.
set -euo pipefail
[ "${1:-}" = get ] || exit 0

declare -A q
while IFS='=' read -r k v; do [ -n "$k" ] && q["$k"]="$v"; done
[ "${q[host]:-}" = github.com ] || exit 0
org="${q[path]%%/*}"
[ -n "$org" ] || exit 0

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
printf 'username=x-access-token\npassword=%s\n' "$("$here/gh-token.sh" "$org")"
