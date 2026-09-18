#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# A SPARQL SERVICE clause in a query to /sparql must not reach the deployment's internal services: the triplestore
# executes it, so an internal target would hand the agent data the ACL never grants, such as the admin store's agents
# and authorizations. Targets: the admin store, the admin store through its backend cache, and a store over loopback,
# which the JVM would otherwise exempt from an outbound proxy.
# SERVICE SILENT turns a refused call into a single empty solution, so the results are checked for data rather than
# the response for a status code: a target that answered binds ?g

for endpoint in "http://fuseki:3030/admin/" "http://varnish-admin/admin/" "http://localhost:3030/admin/"
do
    results=$(curl -k -f -s -G \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -H "Accept: application/sparql-results+xml" \
      "${END_USER_BASE_URL}sparql" \
      --data-urlencode "query=SELECT ?g { SERVICE SILENT <${endpoint}> { GRAPH ?g { ?s ?p ?o } } } LIMIT 1")

    echo "DEBUG: SERVICE <${endpoint}> results: ${results}"

    if grep -q '<binding name="g">' <<< "$results"; then
        echo "SERVICE <${endpoint}> returned data"
        exit 1
    fi
done
