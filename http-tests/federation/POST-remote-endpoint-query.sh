#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Federation query leg: A's client poses a SPARQL Protocol query to B's endpoint, with the
# endpoint URL taken from B's forwarded Link header (runtime discovery, not configuration).
# The query request rides A's proxy, which forwards the method, body and media type.

remote_base="https://test.localhost:4443/"

headers=$(mktemp)
trap 'rm -f "$headers"' EXIT

curl -k -f -s -o /dev/null -D "$headers" \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/rdf+xml" \
  --data-urlencode "uri=${remote_base}" \
  "$END_USER_BASE_URL"

endpoint=$(grep -i '^link:' "$headers" | tr ',' '\n' | grep 'sparql-service-description#endpoint' | sed 's/.*<\([^>]*\)>.*/\1/')

if [ -z "$endpoint" ]; then
  exit 1
fi

# query B's root document graph on the discovered endpoint, through A's proxy

query="SELECT * WHERE { GRAPH <${remote_base}> { ?s ?p ?o } } LIMIT 1"

count=$(curl -k -f -s \
  -X POST \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/sparql-query" \
  -H "Accept: application/sparql-results+xml" \
  --url-query "uri=${endpoint}" \
  --data-binary "$query" \
  "$END_USER_BASE_URL" \
| xmllint --xpath "count(//*[local-name() = 'result'])" -)

if [ "$count" != "1" ]; then
  exit 1
fi
