#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"
purge_backend_cache "$FRONTEND_VARNISH_SERVICE"

# SPARQL update on the <ns> endpoint should not be allowed

curl -k -w "%{http_code}\n" -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}ns" \
  --data-urlencode "update=DELETE WHERE { ?s ?p ?o . }" \
| grep -q "$STATUS_METHOD_NOT_ALLOWED"