#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# GET /sparql with a signed-up agent (no group) should return 200
# The sparql-endpoint authorization grants acl:Read to acl:AuthenticatedAgent regardless of group membership

curl -k -w "%{http_code}\n" -o /dev/null -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT * { ?s ?p ?o } LIMIT 1" \
| grep -q "$STATUS_OK"
