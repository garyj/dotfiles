#!/usr/bin/env bash
# Connect to an RDP server via RD Gateway using xfreerdp v2.
#
# Usage:
#   rdp-connect.sh <server> <gateway> <username> <gw_password> [server_password]
#
# If server_password is omitted, gateway password is used for both.

set -euo pipefail

if [[ $# -lt 4 ]]; then
    echo "Usage: rdp-connect.sh <server> <gateway> <username> <gw_password> [server_password]"
    exit 1
fi

SERVER="$1"
GATEWAY="$2"
USER="$3"
GW_PASS="$4"
RDP_PASS="${5:-$4}"

# Extract domain from DOMAIN\user format, or use username as-is
if [[ "$USER" == *\\* ]]; then
    DOMAIN="${USER%%\\*}"
    USER="${USER#*\\}"
else
    DOMAIN=""
fi

DOMAIN_ARG=""
[[ -n "$DOMAIN" ]] && DOMAIN_ARG="/d:$DOMAIN"

xfreerdp /v:"$SERVER" \
    /u:"$USER" \
    $DOMAIN_ARG \
    /p:"$RDP_PASS" \
    /sec:nla \
    /cert:ignore \
    /g:"$GATEWAY" \
    /gd:"$DOMAIN" \
    /gu:"$USER" \
    /gp:"$GW_PASS" \
    /gt:http \
    /smart-sizing \
    /w:2560 /h:1440
