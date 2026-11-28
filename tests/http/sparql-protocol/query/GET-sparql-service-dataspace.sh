#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A query federates to another dataspace by naming its SPARQL endpoint with SERVICE. The triplestore makes the call,
# and it makes it on behalf of the agent who asked: the platform marks the SERVICE IRI with the agent, the store's
# LinkedDataHub module calls the endpoint as the secretary with On-Behalf-Of, and the endpoint's own access control
# decides. Here the owner, asking the end-user endpoint, reads the admin dataspace, which only the owners may query:
# its root document is a result the end-user endpoint alone never has, and that an anonymous call would be refused

results=$(curl -k -f -s -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT ?g { SERVICE <${ADMIN_BASE_URL}sparql> { GRAPH ?g { <${ADMIN_BASE_URL}> ?p ?o } } } LIMIT 1")

echo "DEBUG: results: ${results}"

grep -q "<uri>${ADMIN_BASE_URL}</uri>" <<< "$results" || { echo "SERVICE <${ADMIN_BASE_URL}sparql> did not answer the owner with the admin root document"; exit 1; }
