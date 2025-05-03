#!/usr/bin/env bash
#
# To use: source ./aws_exp.sh <profile>
#

# Check for aws CLI
if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: aws CLI is not installed or not in PATH." >&2
  return 1 2>/dev/null || exit 1
fi

PROFILE="${1:-default}"

cred_proc="$(aws configure get credential_process --profile "$PROFILE" 2>/dev/null)"
if [[ -n "$cred_proc" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required but not installed." >&2
    return 1 2>/dev/null || exit 1
  fi
  creds_json="$(eval "$cred_proc")"
  export AWS_ACCESS_KEY_ID="$(echo "$creds_json" | jq -r .AccessKeyId)"
  export AWS_SECRET_ACCESS_KEY="$(echo "$creds_json" | jq -r .SecretAccessKey)"
  AWS_SESSION_TOKEN="$(echo "$creds_json" | jq -r .SessionToken)"
  echo "Loaded credentials via credential_process for profile '$PROFILE'."
else
  # If missing keys, warn (do not fail)
  export AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id --profile "$PROFILE" 2>/dev/null || true)"
  export AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key --profile "$PROFILE" 2>/dev/null || true)"
  AWS_SESSION_TOKEN="$(aws configure get aws_session_token --profile "$PROFILE" 2>/dev/null || true)"
  echo "Loaded credentials from disk file for profile '$PROFILE'."
fi

# Unset tokens if they are empty to avoid exporting empty strings
if [[ -z "$AWS_SESSION_TOKEN" || "$AWS_SESSION_TOKEN" == "null" ]]; then
  unset AWS_SESSION_TOKEN
else
  export AWS_SESSION_TOKEN
fi

# Export region (warn if not found)
AWS_DEFAULT_REGION="$(aws configure get region --profile "$PROFILE" 2>/dev/null || true)"
if [[ -z "$AWS_DEFAULT_REGION" ]]; then
  echo "WARNING: No region set for '$PROFILE'." >&2
fi
export AWS_DEFAULT_REGION

# Optionally get AWS account ID from local config, if set
AWS_ACCOUNT_ID="$(aws configure get account_id --profile "$PROFILE" 2>/dev/null || true)"
export AWS_ACCOUNT_ID

export AWS_PROFILE="$PROFILE"

# Show exports (mask secrets)
echo "AWS_PROFILE=$AWS_PROFILE"
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
echo -n "AWS_SECRET_ACCESS_KEY="
[[ -n "$AWS_SECRET_ACCESS_KEY" ]] && printf '%*s' "${#AWS_SECRET_ACCESS_KEY}" '' | tr ' ' '*'
echo
echo "AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION"
echo "AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID"

if [[ -n "${AWS_SESSION_TOKEN:-}" ]]; then
  echo "Session token loaded."
fi
