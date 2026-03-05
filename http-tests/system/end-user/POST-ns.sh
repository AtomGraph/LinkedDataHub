#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# POST /ns (SPARQL query via POST form) is publicly accessible (foaf:Agent has acl:Append via public-namespace authorization)

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/sparql-results+xml" \
  --data-urlencode "query=SELECT * { ?s ?p ?o } LIMIT 1" \
  "${END_USER_BASE_URL}ns" \
| grep -q "$STATUS_OK"
