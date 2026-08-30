#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# create a container whose graph holds a known title

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')

container=$(ldh create-container \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Graph scope one" \
  --slug "$slug" \
  --parent "$END_USER_BASE_URL")

# control: the scoped default graph is non-empty

control=$(curl -k -f -s -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT * { ?s ?p ?o }" \
  --data-urlencode "default-graph-uri=${container}")

control_count=$(echo "$control" | xmllint --xpath 'count(//*[local-name()="result"])' -)

[ "$control_count" -gt 0 ]

# the protocol dataset contains no named graphs, so GRAPH patterns must match nothing

result=$(curl -k -f -s -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT * { GRAPH ?g { ?s ?p ?o } }" \
  --data-urlencode "default-graph-uri=${container}")

result_count=$(echo "$result" | xmllint --xpath 'count(//*[local-name()="result"])' -)

[ "$result_count" -eq 0 ]
