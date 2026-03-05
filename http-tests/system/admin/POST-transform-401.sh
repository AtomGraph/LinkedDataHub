#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# POST /transform without a certificate should return 401
# Only owners have access to /transform via full-control authorization in admin.trig

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "rdf=" \
  "${ADMIN_BASE_URL}transform" \
| grep -q "$STATUS_UNAUTHORIZED"
