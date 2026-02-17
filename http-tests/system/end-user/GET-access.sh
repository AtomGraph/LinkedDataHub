#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# GET /access is publicly accessible (foaf:Agent has acl:Read via access authorization)

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}access" \
| grep -q "$STATUS_OK"
