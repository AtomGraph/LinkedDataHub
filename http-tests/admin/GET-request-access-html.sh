#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

# test the "Request access" HTML form

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: text/html' \
  --data-urlencode "access-to=${END_USER_BASE_URL}" \
  "${ADMIN_BASE_URL}request%20access" \
| grep -q "$STATUS_OK"