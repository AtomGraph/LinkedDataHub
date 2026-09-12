#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# GET /sparql without a certificate is denied with 403 (LDH issues no 401 challenge for unauthenticated requests)
# Unlike /ns, the sparql-endpoint authorization uses acl:AuthenticatedAgent (not foaf:Agent),
# so unauthenticated access is not allowed

actual=$(curl -k -w "%{http_code}" -o /dev/null -s -G \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT * { ?s ?p ?o } LIMIT 1")
expected="$STATUS_FORBIDDEN"
echo "DEBUG: Expected: $expected"
echo "DEBUG: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"
