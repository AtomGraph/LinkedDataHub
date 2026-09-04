#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# create two containers whose graphs hold distinct titles

slug_one=$(uuidgen | tr '[:upper:]' '[:lower:]')
slug_two=$(uuidgen | tr '[:upper:]' '[:lower:]')

container_one=$(ldh create container \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Graph scope one" \
  --slug "$slug_one" \
  --parent "$END_USER_BASE_URL")

container_two=$(ldh create container \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Graph scope two" \
  --slug "$slug_two" \
  --parent "$END_USER_BASE_URL")

# query via POST directly (application/sparql-query): dataset params go in the request URI query string.
# The container URI is built from a lowercase UUID slug, so only ':' and '/' need percent-encoding.

container_one_enc="${container_one//:/%3A}"
container_one_enc="${container_one_enc//\//%2F}"

result=$(curl -k -f -s -X POST \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  -H "Content-Type: application/sparql-query" \
  "${END_USER_BASE_URL}sparql?default-graph-uri=${container_one_enc}" \
  --data-binary "SELECT ?title { ?s <http://purl.org/dc/terms/title> ?title }")

# the scoped graph's title is visible

echo "$result" | grep -q "Graph scope one"

# the other document's graph is invisible

if echo "$result" | grep -q "Graph scope two"; then
    exit 1
fi
