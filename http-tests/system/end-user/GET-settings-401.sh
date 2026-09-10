#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# GET /settings without a certificate is denied with 403 (LDH issues no 401 challenge for unauthenticated requests)
# Only owners have Read access to /settings via the full-control authorization

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}settings")
expected="$STATUS_FORBIDDEN"
echo "DEBUG: Expected: $expected"
echo "DEBUG: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"
