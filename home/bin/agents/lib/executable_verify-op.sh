#!/usr/bin/env bash
#
# verify-op.sh <vault> <token-op-ref>  --  check an agent's 1Password service account
# is scoped correctly. Run this as YOURSELF, not through the agent wrapper: step 1
# reads the SA token out of your personal 1Password, and the rest re-runs op as the
# service account to see what it can actually reach.
#
#   verify-op.sh AGLara 'op://Personal/1P Service Account - Lara/password'
#
# What it does:
#   1. Reads the agent's SA token
#   2. Re-runs op AS the service account and confirms it can:
#        - list vaults (expect: <vault> only)
#        - list and read a secret in <vault> (proves read access; value never shown)
#   3. Confirms the SA CANNOT reach your personal vault (expects an error = good).
#
# Read-only. Changes nothing. Never prints a secret value.

set -euo pipefail

VAULT="${1:?usage: verify-op.sh <vault> <token-op-ref>}"
TOKEN_REF="${2:?usage: verify-op.sh <vault> <token-op-ref>}"
PERSONAL_VAULT='Personal'

command -v op >/dev/null || { echo "op not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq not found" >&2; exit 1; }

if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "ERROR: OP_SERVICE_ACCOUNT_TOKEN is already set in this shell." >&2
  echo "       Open a clean shell so step 1 uses your personal 1Password." >&2
  exit 1
fi

echo "==> 1. Reading the service-account token"
SA_TOKEN="$(op read "$TOKEN_REF")"
[ -n "$SA_TOKEN" ] || { echo "ERROR: empty token from $TOKEN_REF" >&2; exit 1; }
echo "    ok: token retrieved (${#SA_TOKEN} chars)"

# From here on, every op call runs AS the service account, scoped per-command.
as_sa() { env OP_SERVICE_ACCOUNT_TOKEN="$SA_TOKEN" "$@"; }

echo
echo "==> 2. Vaults the service account can see (expect $VAULT; must NOT list $PERSONAL_VAULT):"
as_sa op vault list

echo
echo "==> 3. Items in $VAULT (titles/categories only, no secret values):"
as_sa op item list --vault "$VAULT"

echo
echo "==> 4. Proving the SA can READ a secret (reports field count only, value hidden):"
first_title="$(as_sa op item list --vault "$VAULT" --format=json | jq -r '.[0].title // empty')"
if [ -n "$first_title" ]; then
  nfields="$(as_sa op item get "$first_title" --vault "$VAULT" --format=json | jq -r '.fields | length')"
  echo "    ok: read '$first_title' from $VAULT ($nfields fields, values not shown)"
else
  echo "    ($VAULT appears empty; add a secret to test a real read)"
fi

echo
echo "==> 5. Proving the SA CANNOT reach '$PERSONAL_VAULT' (an error here is the PASS):"
if as_sa op item list --vault "$PERSONAL_VAULT" >/dev/null 2>&1; then
  echo "    WARNING: the SA can see '$PERSONAL_VAULT' -- scoping is too broad, tighten it!"
else
  echo "    ok: '$PERSONAL_VAULT' is not accessible to this service account"
fi

echo
echo "==> Done. If steps 2-4 succeeded, step 5 was blocked, and no prompt appeared"
echo "    during steps 2-5, the service account is scoped correctly."
