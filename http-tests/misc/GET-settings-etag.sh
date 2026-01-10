#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Test: GET /settings with If-None-Match - Conditional GET with matching ETag

# First GET to obtain ETag
response=$(curl -i -k -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}settings")

# Extract ETag
etag=$(echo "$response" | grep -i "ETag:" | sed 's/ETag: //i' | tr -d '\r\n')

# Second GET with If-None-Match
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -H "If-None-Match: $etag" \
  "${END_USER_BASE_URL}settings" \
| grep -q "$STATUS_NOT_MODIFIED"
