#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Test: PATCH /settings - Empty result (should fail with 422)

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -X PATCH \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/sparql-update" \
  -d "DELETE WHERE { ?s ?p ?o }" \
  "${END_USER_BASE_URL}settings" \
| grep -q "$STATUS_UNPROCESSABLE_ENTITY"
