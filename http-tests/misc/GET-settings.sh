#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Test: GET /settings - Retrieve current application settings

response=$(curl -k -w "%{http_code}\n" -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}settings")

# Extract status code (last line) and body (everything else)
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

# Verify 200 OK response
if [ "$status" != "$STATUS_OK" ]; then
  exit 1
fi

# Verify response contains expected application data
if ! echo "$body" | grep -q '<urn:linkeddatahub:apps/end-user>'; then
  exit 1
fi

if ! echo "$body" | grep -q '<https://w3id.org/atomgraph/linkeddatahub/apps#EndUserApplication>'; then
  exit 1
fi

if ! echo "$body" | grep -q '"LinkedDataHub"'; then
  exit 1
fi

if ! echo "$body" | grep -q '<https://localhost:4443>'; then
  exit 1
fi
