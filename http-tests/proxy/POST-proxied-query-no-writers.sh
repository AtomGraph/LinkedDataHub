#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# grant the agent acl:Append on the SPARQL endpoint only (not on the root URL)

create-authorization.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --label "Append authorization for SPARQL endpoint" \
  --agent "$AGENT_URI" \
  --to "${END_USER_BASE_URL}sparql" \
  --append

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# execute SPARQL query using LDH as a proxy
# agent has acl:Append on /sparql but NOT on the root URL —
# currently returns 403 because AuthorizationFilter checks ACL on the root proxy URL

http_code=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/sparql-results+xml' \
  --url-query "uri=${END_USER_BASE_URL}sparql" \
  --data 'SELECT (COUNT(*) AS ?count) WHERE { ?s ?p ?o }' \
  "$END_USER_BASE_URL")

if [ "$http_code" -ne 200 ]; then
    echo "Expected HTTP 200, got: $http_code"
    exit 1
fi
