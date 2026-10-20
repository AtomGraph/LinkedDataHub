#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# The platform refuses a result past MAX_QUERY_RESPONSE_LENGTH and hangs up, but a cached Varnish fetch runs on without its
# client, and the triplestore with it: an unbounded three-way cross join used to be read until the main store was full
# (3 GB, ~25 s of evaluation). SPARQL results are kept in a store of their own (VARNISH_SPARQL_STORAGE), so the fetch fails
# once the result outgrows it, which closes the backend connection and makes the triplestore abandon the query. That
# failure is what is counted here: an allocator failure in the SPARQL store, the fetch having been cut where it was bounded

compose=(docker compose -f "$HTTP_TEST_ROOT/../../docker-compose.yml" -f "$HTTP_TEST_ROOT/docker-compose.http-tests.yml" --env-file "$HTTP_TEST_ROOT/.env")

sparql_store_failures()
{
    "${compose[@]}" exec -T "$END_USER_VARNISH_SERVICE" varnishstat -1 -f SMA.sparql.c_fail | awk '{ print $2 }'
}

failures_before=$(sparql_store_failures)

query="SELECT * { GRAPH ?g1 { ?a ?b ?c } GRAPH ?g2 { ?d ?e ?f } GRAPH ?g3 { ?h ?i ?j } }"

start=$(date +%s)
actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/sparql-results+xml" \
  --data-urlencode "query=$query" \
  "${END_USER_BASE_URL}sparql")
expected="$STATUS_BAD_GATEWAY"
echo "DEBUG: Expected: $expected"
echo "DEBUG: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"

# the fetch outlives the response, so wait for it to end - well inside the triplestore's 60 s query timeout, which would
# end it as well, and which this test must not be passing on

for _ in $(seq 1 20); do
    failures_after=$(sparql_store_failures)
    [ "$failures_after" -gt "$failures_before" ] && break
    sleep 1
done
echo "DEBUG: SPARQL store allocator failures: before $failures_before, after $failures_after, $(( $(date +%s) - start )) s after the request"
[ "$failures_after" -gt "$failures_before" ]
