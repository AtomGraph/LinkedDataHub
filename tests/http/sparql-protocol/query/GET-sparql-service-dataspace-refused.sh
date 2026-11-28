#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# The federation leg is the asking agent's own, and the target's door decides it: a signed-up agent may query the
# end-user endpoint (GET-sparql.sh) but not the admin dataspace's, which the owners alone read. The call reaches the
# admin endpoint on the agent's behalf and is refused there, so SERVICE SILENT gives no data, and SERVICE fails the query

results=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT ?g { SERVICE SILENT <${ADMIN_BASE_URL}sparql> { GRAPH ?g { ?s ?p ?o } } } LIMIT 1")

echo "DEBUG: SILENT results: ${results}"

if grep -q '<binding name="g">' <<< "$results"; then
    echo "SERVICE <${ADMIN_BASE_URL}sparql> answered an agent the admin dataspace does not grant"
    exit 1
fi

status=$(curl -k -w "%{http_code}" -o /dev/null -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT ?g { SERVICE <${ADMIN_BASE_URL}sparql> { GRAPH ?g { ?s ?p ?o } } } LIMIT 1")

echo "DEBUG: without SILENT: ${status}"
[ "$status" != "$STATUS_OK" ] || { echo "a refused SERVICE call did not fail the query"; exit 1; }
