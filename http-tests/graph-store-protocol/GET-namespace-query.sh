#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

# owner access

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { ?s ?p ?o } LIMIT 1" \
  "${END_USER_BASE_URL}ns" \
| grep -q "$STATUS_OK"

# authenticated agent access

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { ?s ?p ?o } LIMIT 1" \
  "${END_USER_BASE_URL}ns" \
| grep -q "$STATUS_OK"

# public access

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -G \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { ?s ?p ?o } LIMIT 1" \
  "${END_USER_BASE_URL}ns" \
| grep -q "$STATUS_OK"