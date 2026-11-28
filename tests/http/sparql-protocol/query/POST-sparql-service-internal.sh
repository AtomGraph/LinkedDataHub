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
# through SPARQL SERVICE either. The platform refuses it with 400 before it goes out

endpoint="http://fuseki:3030/admin/"

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/sparql-results+xml" \
  --data-urlencode "query=SELECT ?g { SERVICE SILENT <${endpoint}> { GRAPH ?g { ?s ?p ?o } } } LIMIT 1" \
  "${END_USER_BASE_URL}sparql")

echo "DEBUG: SERVICE <${endpoint}> Expected: $STATUS_BAD_REQUEST Got: $status"
[ "$status" = "$STATUS_BAD_REQUEST" ] || exit 1
