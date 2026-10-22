#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# SPARQL update on the <ns> endpoint should not be allowed

headers=$(curl -k -o /dev/null -s -D - \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}ns" \
  --data-urlencode "update=DELETE WHERE { ?s ?p ?o . }")

# the 405 names the methods the resource allows

status=$(head -n 1 <<< "$headers" | cut -d ' ' -f 2)
allow=$(grep -i '^allow:' <<< "$headers" | tr -d '\r' || true)
echo "DEBUG: Expected status: $STATUS_METHOD_NOT_ALLOWED"
echo "DEBUG: Got status: $status"
echo "DEBUG: Got: $allow"
[ "$status" = "$STATUS_METHOD_NOT_ALLOWED" ]
grep -qw "GET" <<< "$allow"
grep -qw "POST" <<< "$allow"
