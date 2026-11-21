#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A query federates to another dataspace of the deployment by naming that dataspace's public SPARQL endpoint. The
# platform authorizes the agent for the endpoint as a GET of it would be - here the owner reading the admin
# dataspace's - and the store reaches the dataspace's dataset: the admin dataspace's root document is a result the
# end-user endpoint alone never has

results=$(curl -k -f -s -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT ?g { SERVICE <${ADMIN_BASE_URL}sparql> { GRAPH ?g { <${ADMIN_BASE_URL}> ?p ?o } } } LIMIT 1")

echo "DEBUG: results: ${results}"

grep -q "<uri>${ADMIN_BASE_URL}</uri>" <<< "$results" || { echo "SERVICE <${ADMIN_BASE_URL}sparql> did not answer with the admin root document"; exit 1; }
