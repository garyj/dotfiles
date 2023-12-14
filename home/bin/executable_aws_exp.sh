#!/bin/bash

# This script is used to configure AWS CLI environment variables for a specific profile.
# It takes a profile name as an argument (default is 'default') and retrieves the corresponding AWS configuration.
# Then it exports the config into environment variables:
#
# Script is designed to be `source`d
#
# Require: aws-cli

# no -ue here as the script is designed to be sourced so we don't want to parent shell to exist on error
set -fo pipefail

PROFILE=${1:-default}

export AWS_PROFILE=$PROFILE
export AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id --profile $PROFILE)"
export AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key --profile $PROFILE)"
export AWS_DEFAULT_REGION="$(aws configure get region --profile $PROFILE)"
export AWS_SESSION_TOKEN="$(aws configure get aws_session_token --profile $PROFILE)"
export AWS_SECURITY_TOKEN="$(aws configure get aws_security_token --profile $PROFILE)"
export AWS_REGION_NAME="$(aws configure get region --profile $PROFILE)"
export AWS_ACCOUNT_ID="$(aws configure get account_id --profile $PROFILE)"

echo AWS_PROFILE=$AWS_PROFILE
echo AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
echo AWS_SECRET_ACCESS_KEY=$(echo $AWS_SECRET_ACCESS_KEY | tr '[:print:]' '*')
echo AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
echo AWS_REGION_NAME=$AWS_REGION_NAME
echo AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID
if [[ $AWS_SESSION_TOKEN ]] && [[ $AWS_SECURITY_TOKEN ]]; then
  echo "AWS_*_TOKENS loaded"
else
  unset AWS_SESSION_TOKEN AWS_SECURITY_TOKEN
fi
