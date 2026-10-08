#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Each SPARQL query form through the proxy, against a cross-origin endpoint (the admin app's), since a ?uri= under
# the requesting app's own base URI is served locally and never reaches ProxyRequestFilter. The proxy tells the
# answers apart by content type alone: a graph comes back as RDF, a result set and an ASK's boolean both as SPARQL
# results, and the boolean has to be served as one rather than read as rows. The owner is used because the admin
# SPARQL endpoint is ACL-protected.

# proxied_query <accept> <query>: prints the body, then the HTTP status on a line of its own

proxied_query()
{
    curl -k -s \
      -w '\n%{http_code}' \
      -X POST \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H 'Content-Type: application/sparql-query' \
      -H "Accept: $1" \
      --url-query "uri=${ADMIN_BASE_URL}sparql" \
      --data "$2" \
      "$END_USER_BASE_URL"
}

# run <accept> <query>: sets $http_code and $body

run()
{
    response=$(proxied_query "$1" "$2")
    http_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')
}

# check <accept> <query> <expected> <got>: <got> is what the caller extracted from $body

check()
{
    echo "DEBUG: Accept: $1 Query: $2"
    echo "DEBUG: Expected: 200 $3"
    echo "DEBUG: Got: $http_code $4"

    if [ "$http_code" != "200" ] || [ "$4" != "$3" ]; then
        echo "DEBUG: Mismatch! Body: $body"
        exit 1
    fi
}

# every document is a named graph, so the admin dataset matches inside GRAPH

# CONSTRUCT: a graph, as RDF

query='CONSTRUCT { ?s ?p ?o } WHERE { GRAPH ?g { ?s ?p ?o } } LIMIT 3'
run 'application/n-triples' "$query"
check 'application/n-triples' "$query" '3' "$(echo "$body" | rapper -q --input ntriples --output ntriples /dev/stdin - | wc -l | tr -d ' ')"

# SELECT: rows, as SPARQL results

query='SELECT ?s WHERE { GRAPH ?g { ?s ?p ?o } } LIMIT 2'
run 'application/sparql-results+xml' "$query"
check 'application/sparql-results+xml' "$query" '2' "$(echo "$body" | xmllint --xpath "count(//*[local-name() = 'result'])" -)"

# ASK: a boolean, as SPARQL results, true and false, in XML and JSON

ask_true='ASK { GRAPH ?g { ?s ?p ?o } }'
ask_false='ASK { GRAPH ?g { ?s ?p <urn:ldh:test:absent> } }'

for query in "$ask_true" "$ask_false"; do
    if [ "$query" = "$ask_true" ]; then expected='true'; else expected='false'; fi

    run 'application/sparql-results+xml' "$query"
    check 'application/sparql-results+xml' "$query" "$expected" "$(echo "$body" | xmllint --xpath "string(//*[local-name() = 'boolean'])" - 2>/dev/null || true)"

    run 'application/sparql-results+json' "$query"
    check 'application/sparql-results+json' "$query" "$expected" "$(echo "$body" | tr -d ' \n' | sed -n 's/.*"boolean":\([a-z]*\).*/\1/p')"
done
