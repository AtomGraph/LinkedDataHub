#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# The POST form of GET-sparql-service-internal.sh: a query sent in the request body must not reach the admin store
# through SPARQL SERVICE either. SERVICE SILENT turns a refused call into a single empty solution, so a bound ?g means
# the admin store answered

endpoint="http://fuseki:3030/admin/"

results=$(curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/sparql-results+xml" \
  --data-urlencode "query=SELECT ?g { SERVICE SILENT <${endpoint}> { GRAPH ?g { ?s ?p ?o } } } LIMIT 1" \
  "${END_USER_BASE_URL}sparql")

echo "DEBUG: SERVICE <${endpoint}> results: ${results}"

if grep -q '<binding name="g">' <<< "$results"; then
    echo "SERVICE <${endpoint}> returned data"
    exit 1
fi
