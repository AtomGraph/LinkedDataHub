#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Execute a SPARQL query against a cross-origin endpoint (the admin app's SPARQL
# endpoint) using the end-user app as a proxy. Because admin.localhost is a different
# origin than the end-user app, the request goes through ProxyRequestFilter, which
# fetches the remote endpoint and re-serializes the SPARQL results back to the caller.
# The owner is used because the admin SPARQL endpoint is ACL-protected.

response_body=$(curl -k -s \
  -X POST \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/sparql-results+xml' \
  --url-query "uri=${ADMIN_BASE_URL}sparql" \
  --data 'SELECT (COUNT(*) AS ?count) WHERE { ?s ?p ?o }' \
  "$END_USER_BASE_URL")

http_code=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/sparql-results+xml' \
  --url-query "uri=${ADMIN_BASE_URL}sparql" \
  --data 'SELECT (COUNT(*) AS ?count) WHERE { ?s ?p ?o }' \
  "$END_USER_BASE_URL")

# verify successful status and that the proxy re-serialized actual SPARQL results
if [ "$http_code" -ne 200 ] || [[ "$response_body" != *"http://www.w3.org/2005/sparql-results#"* ]]; then
    exit 1
fi
