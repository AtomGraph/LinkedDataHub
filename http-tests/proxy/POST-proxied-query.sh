#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the writers group - POST requests count as write operations

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# execute SPARQL query using LDH as a proxy

response_body=$(curl -k -s \
  -X POST \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/sparql-results+xml' \
  --url-query "uri=${END_USER_BASE_URL}sparql" \
  --data 'SELECT (COUNT(*) AS ?count) WHERE { ?s ?p ?o }' \
  "$END_USER_BASE_URL")

http_code=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/sparql-results+xml' \
  --url-query "uri=${END_USER_BASE_URL}sparql" \
  --data 'SELECT (COUNT(*) AS ?count) WHERE { ?s ?p ?o }' \
  "$END_USER_BASE_URL")

# verify response has non-empty body and successful status
if [ "$http_code" -ne 200 ] || [ -z "$response_body" ]; then
    exit 1
fi