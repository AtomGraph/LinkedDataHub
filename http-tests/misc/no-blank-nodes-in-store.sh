#!/usr/bin/env bash
set -euo pipefail

# The invariant, asserted as an invariant rather than per write path: the data LDH writes is
# blank-node-free. Every write through the document resource skolemizes, and PATCH, PUT and POST each
# have a test for that - but those enumerate the paths someone thought of. PackageService, which
# materializes a package's ontology by writing straight to the graph store (to avoid a self-request
# deadlock from inside OntologyFilter), was not one of them, and went years without skolemizing.
#
# This is what makes the invariant testable without knowing the paths: ask the store. It is a canary
# rather than a proof - it only sees what the tests before it happened to leave behind - which is
# worth more than it sounds, because those tests exercise most of the write surface.
#
# Why it matters beyond tidiness: the entity tag is a digest over a sorted N-Triples serialization,
# canonical only while no blank nodes are stored. Jena's _:bN labels are not stable across reads, so a
# stored blank node gives its document a different tag on every read - breaking conditional GET and
# making every conditional write against it impossible to satisfy.

function count_blank_nodes()
{
    curl -k -f -s -G \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: application/sparql-results+json" \
      --data-urlencode 'query=SELECT (COUNT(*) AS ?n) WHERE { GRAPH ?g { ?s ?p ?o } FILTER(isBlank(?s) || isBlank(?o)) }' \
      "$1" \
    | tr -d ' \n' \
    | sed -En 's/.*"n":\{[^}]*"value":"([0-9]+)".*/\1/p'
}

function list_offending_graphs()
{
    curl -k -f -s -G \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: application/sparql-results+json" \
      --data-urlencode 'query=SELECT DISTINCT ?g WHERE { GRAPH ?g { ?s ?p ?o } FILTER(isBlank(?s) || isBlank(?o)) } LIMIT 10' \
      "$1"
}

for endpoint in "${END_USER_BASE_URL}sparql" "${ADMIN_BASE_URL}sparql"
do
    n=$(count_blank_nodes "$endpoint")
    echo "DEBUG: $endpoint blank-node triples: ${n:-<unknown>}"

    [ -n "$n" ] || { echo "DEBUG: could not count blank nodes at $endpoint" >&2; exit 1; }

    if [ "$n" != "0" ]; then
        echo "DEBUG: $n blank-node triples in the store - some write path is not skolemizing" >&2
        list_offending_graphs "$endpoint" >&2
        exit 1
    fi
done
