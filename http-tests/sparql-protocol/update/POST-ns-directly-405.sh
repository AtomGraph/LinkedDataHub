#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# SPARQL update on the <ns> endpoint should not be allowed

(
curl -k -w "%{http_code}\n" -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/sparql-update" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}ns" \
  --data-binary @- <<EOF
DELETE WHERE 
{
  ?s ?p ?o .
}
EOF
) \
| grep -q "$STATUS_METHOD_NOT_ALLOWED"