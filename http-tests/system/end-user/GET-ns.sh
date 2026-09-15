#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# GET /ns is publicly accessible (foaf:Agent has acl:Read via public-namespace authorization)

actual=$(curl -k -w "%{http_code}" -o /dev/null -s -G \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}ns" \
  --data-urlencode "query=SELECT * { ?s ?p ?o } LIMIT 1")
expected="$STATUS_OK"
echo "DEBUG: Expected: $expected"
echo "DEBUG: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"
