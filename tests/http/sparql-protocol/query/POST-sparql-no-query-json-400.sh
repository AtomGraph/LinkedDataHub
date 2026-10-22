#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# a form POST carrying no query is a client error, also when the client accepts only a results format the error
# description cannot be written in: the 400 is answered in Turtle rather than failing the negotiation

headers=$(curl -k -o /dev/null -s -D - \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/sparql-results+json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "default-graph-uri=${END_USER_BASE_URL}" \
  "${END_USER_BASE_URL}sparql")

status=$(head -n 1 <<< "$headers" | cut -d ' ' -f 2)
content_type=$(grep -i '^content-type:' <<< "$headers" | tr -d '\r' || true)
echo "DEBUG: Expected status: $STATUS_BAD_REQUEST"
echo "DEBUG: Got status: $status"
echo "DEBUG: Got: $content_type"
[ "$status" = "$STATUS_BAD_REQUEST" ]
grep -qi "text/turtle" <<< "$content_type"
