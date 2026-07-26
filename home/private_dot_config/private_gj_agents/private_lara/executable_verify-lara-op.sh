#!/usr/bin/env bash
#
# verify-lara-op.sh  --  Phase 1 check for the Lara 1Password service account.
#
# What it does:
#   1. Reads the Lara SA token
#   2. Re-runs op AS the service account and confirms it can:
#        - list vaults (expect: AGLara only)
#        - list and read a secret in AGLara (proves read access; value never shown)
#   3. Confirms the SA CANNOT reach your personal vault (expects an error = good).
#
# Read-only. Changes nothing. Never prints a secret value.

set -euo pipefail

TOKEN_REF='op://Personal/1P Service Account - Lara/password'
PERSONAL_VAULT='Personal'

command -v op >/dev/null || { echo "op not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq not found" >&2; exit 1; }

if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "ERROR: OP_SERVICE_ACCOUNT_TOKEN is already set in this shell." >&2
  echo "       Open a clean shell so step 1 uses your personal 1Password." >&2
  exit 1
fi

echo "==> 1. Reading the Lara token"
LARA_TOKEN="$(op read "$TOKEN_REF")"
[ -n "$LARA_TOKEN" ] || { echo "ERROR: empty token from $TOKEN_REF" >&2; exit 1; }
echo "    ok: token retrieved (${#LARA_TOKEN} chars)"

# From here on, every op call runs AS the service account, scoped per-command.
as_lara() { env OP_SERVICE_ACCOUNT_TOKEN="$LARA_TOKEN" "$@"; }

echo
echo "==> 2. Vaults the Lara service account can see (expect AGLara; must NOT list $PERSONAL_VAULT):"
as_lara op vault list

echo
echo "==> 3. Items in AGLara (titles/categories only, no secret values):"
as_lara op item list --vault AGLara

echo
echo "==> 4. Proving the SA can READ a secret (reports field count only, value hidden):"
first_title="$(as_lara op item list --vault AGLara --format=json | jq -r '.[0].title // empty')"
if [ -n "$first_title" ]; then
  nfields="$(as_lara op item get "$first_title" --vault AGLara --format=json | jq -r '.fields | length')"
  echo "    ok: read '$first_title' from AGLara ($nfields fields, values not shown)"
else
  echo "    (AGLara appears empty; add a secret to test a real read)"
fi

echo
echo "==> 5. Proving the SA CANNOT reach '$PERSONAL_VAULT' (an error here is the PASS):"
if as_lara op item list --vault "$PERSONAL_VAULT" >/dev/null 2>&1; then
  echo "    WARNING: the SA can see '$PERSONAL_VAULT' -- scoping is too broad, tighten it!"
else
  echo "    ok: '$PERSONAL_VAULT' is not accessible to the Lara service account"
fi

echo
echo "==> Done. If steps 2-4 succeeded, step 5 was blocked, and no prompt appeared"
echo "    during steps 2-5, the service account is scoped correctly."
