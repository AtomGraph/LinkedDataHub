#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# SPARQL query on the <ns> endpoint should succeed

curl -k -w "%{http_code}\n" -f -s -o /dev/null -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}ns" \
  --data-urlencode "query=SELECT * { ?s ?p ?o }" \
| grep -q "$STATUS_OK"