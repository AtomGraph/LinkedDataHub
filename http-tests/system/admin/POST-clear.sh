#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# POST /clear with owner should succeed
# Owner POSTs the end-user namespace ontology URI to clear it from memory (reload on next request)

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: text/turtle" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "uri=${END_USER_BASE_URL}ns#" \
  "${ADMIN_BASE_URL}clear" \
| grep -qE "^($STATUS_OK|$STATUS_NO_CONTENT)$"
