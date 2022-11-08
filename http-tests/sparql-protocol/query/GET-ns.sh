#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

# SPARQL query on the <ns> endpoint should succeed

curl -k "%{http_code}\n" -f -s -G \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT * { ?s ?p ?o }" \
| grep -q "${STATUS_OK}"