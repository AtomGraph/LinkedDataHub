#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# The federation leg is the agent's own: a signed-up agent may query the end-user endpoint (GET-sparql.sh) but not
# the admin dataspace's, which the owners alone read, so a SERVICE naming it is refused with 403 for the whole
# query - SILENT or not, since the refusal is the platform's decision, not a failed call

for silent in "" "SILENT"
do
    status=$(curl -k -w "%{http_code}" -o /dev/null -s -G \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -H "Accept: application/sparql-results+xml" \
      "${END_USER_BASE_URL}sparql" \
      --data-urlencode "query=SELECT ?g { SERVICE ${silent} <${ADMIN_BASE_URL}sparql> { GRAPH ?g { ?s ?p ?o } } } LIMIT 1")

    echo "DEBUG: SERVICE ${silent} Expected: $STATUS_FORBIDDEN Got: $status"
    [ "$status" = "$STATUS_FORBIDDEN" ] || exit 1
done
