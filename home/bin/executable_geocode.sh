#!/usr/bin/env bash

# This script is used to geocode an address using the Google Maps Geocoding API.
# It also requires a valid Google Maps API key, which should be stored in the .creds/misc_api_creds file in the user's
# home directory.
#
# Requirements: curl, jq, xclip

set -eufo pipefail
. $HOME/.creds/misc_api_creds
address=$(printf %s "$1" | jq -sRr @uri)
result=$(curl "https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=${GOOGLE_MAPS_API_KEY}")
echo "$result" | jq .
echo "--- formatted address ---"
formatted_address=$(echo "$result" | jq -r '.results[0].formatted_address')
echo "$formatted_address"

echo "$formatted_address" | xclip -selection clipboard


