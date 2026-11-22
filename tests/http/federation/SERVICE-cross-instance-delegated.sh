#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
initialize_dataset "$REMOTE_END_USER_BASE_URL" "$TMP_REMOTE_END_USER_DATASET" "$REMOTE_END_USER_ENDPOINT_URL"
initialize_dataset "$REMOTE_ADMIN_BASE_URL" "$TMP_REMOTE_ADMIN_DATASET" "$REMOTE_ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Federation across instances: A's owner asks A's endpoint a query whose SERVICE names B's. A's triplestore makes the
# call on the owner's behalf - A's secretary presenting its certificate, On-Behalf-Of naming the owner - because B asks
# for a client certificate. B verifies the delegation as it verifies a write A's proxy sends (the owner's WebID says the
# secretary delegates for them) and applies its own access control: its endpoint answers any authenticated agent, and an
# anonymous caller is refused (GET-sparql-401.sh), so an answer is the delegation at work. B's root document is in B's
# store alone

results=$(curl -k -f -s -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=SELECT ?g { SERVICE <${REMOTE_END_USER_BASE_URL}sparql> { GRAPH ?g { <${REMOTE_END_USER_BASE_URL}> ?p ?o } } } LIMIT 1")

echo "DEBUG: results: ${results}"

grep -q "<uri>${REMOTE_END_USER_BASE_URL}</uri>" <<< "$results" || { echo "SERVICE <${REMOTE_END_USER_BASE_URL}sparql> did not answer A's owner with B's root document"; exit 1; }
