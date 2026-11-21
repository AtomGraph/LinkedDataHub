#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A SPARQL SERVICE clause in a query to /sparql must not reach the deployment's internal services: the triplestore
# executes it, so an internal target would hand the agent data the ACL never grants, such as the admin store's agents
# and authorizations. Targets: the admin store, the admin store through its backend cache, and a store over loopback,
# which the JVM would otherwise exempt from an outbound proxy.
# The platform refuses the query before it goes out, with 400: a dataspace of the deployment is federated through its
# public endpoint (GET-sparql-service-dataspace.sh), anything else internal is not reached. SILENT does not help: it
# suppresses a failed call, not the decision whether the call may be made

for endpoint in "http://fuseki:3030/admin/" "http://varnish-admin/admin/" "http://localhost:3030/admin/"
do
    status=$(curl -k -w "%{http_code}" -o /dev/null -s -G \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -H "Accept: application/sparql-results+xml" \
      "${END_USER_BASE_URL}sparql" \
      --data-urlencode "query=SELECT ?g { SERVICE SILENT <${endpoint}> { GRAPH ?g { ?s ?p ?o } } } LIMIT 1")

    echo "DEBUG: SERVICE <${endpoint}> Expected: $STATUS_BAD_REQUEST Got: $status"
    [ "$status" = "$STATUS_BAD_REQUEST" ] || exit 1
done
