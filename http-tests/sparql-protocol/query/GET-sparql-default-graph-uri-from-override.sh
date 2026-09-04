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

# the protocol dataset description overrides the query's FROM clause (SPARQL 1.1 Protocol):
# FROM <container_two> in the query text loses to default-graph-uri=<container_one>

result=$(curl -k -f -s -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT ?title FROM <${container_two}> WHERE { ?s <http://purl.org/dc/terms/title> ?title }" \
  --data-urlencode "default-graph-uri=${container_one}")

# the protocol-specified graph's title is visible

echo "$result" | grep -q "Graph scope one"

# the FROM graph's title is not

if echo "$result" | grep -q "Graph scope two"; then
    exit 1
fi
