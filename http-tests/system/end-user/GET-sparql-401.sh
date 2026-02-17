#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# GET /sparql without a certificate should return 401
# Unlike /ns, the sparql-endpoint authorization uses acl:AuthenticatedAgent (not foaf:Agent),
# so unauthenticated access is not allowed

curl -k -w "%{http_code}\n" -o /dev/null -s -G \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT * { ?s ?p ?o } LIMIT 1" \
| grep -q "$STATUS_UNAUTHORIZED"
