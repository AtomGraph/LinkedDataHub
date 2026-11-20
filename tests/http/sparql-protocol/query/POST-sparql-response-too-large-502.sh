#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# A query whose result is longer than MAX_QUERY_RESPONSE_LENGTH (5 MiB unless set) is refused with 502 and a description,
# rather than buffered by the endpoint and handed to the caller. A three-way cross join of the dataset's triples is far
# past the limit on any dataset this suite initializes.
#
# Two guards bound the result, and which one trips first is a race. The platform reads the result through the end-user
# Varnish, which caches it and fetches ahead of the platform's read as fast as the triplestore writes, bounded by its
# SPARQL store (VARNISH_SPARQL_STORAGE, 64M unless set); the platform bounds its own read at MAX_QUERY_RESPONSE_LENGTH.
# When the platform reads the limit first, it refuses the result: the description is typed ldh:ResponseTooLarge. When
# the store fills first, Varnish ends the fetch and cuts the platform's read short: the description says so in its title.
# The triplestore writes faster than the platform reads (this stack logs the wire at DEBUG), so either happens in CI.
# Either way the caller gets no more than the limit and a 502 with a description, which is what is asserted

query="SELECT * { GRAPH ?g1 { ?a ?b ?c } GRAPH ?g2 { ?d ?e ?f } GRAPH ?g3 { ?h ?i ?j } } LIMIT 100000"

response=$(mktemp)
actual=$(curl -k -w "%{http_code}" -o "$response" -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/n-triples" \
  --data-urlencode "query=$query" \
  "${END_USER_BASE_URL}sparql")
expected="$STATUS_BAD_GATEWAY"
echo "DEBUG: Expected: $expected"
echo "DEBUG: Got: $actual"
echo "DEBUG: Body: $(head -c 2000 "$response")"
echo "$actual" | grep -qE "^(${expected})$"
grep -q "<http://www.w3.org/2011/http#statusCodeValue> \"502\"" "$response"
if grep -q "<https://w3id.org/atomgraph/linkeddatahub#ResponseTooLarge>" "$response"; then
    echo "DEBUG: the platform refused the result at its limit"
else
    echo "DEBUG: the Varnish store cut the result short before the platform's limit"
    grep -q "<http://purl.org/dc/terms/title> \"Response ended before it was complete\"" "$response"
fi
rm -f "$response"

# the same pattern, bounded to a result well under the limit, is answered

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/sparql-results+xml" \
  --data-urlencode "query=SELECT * { GRAPH ?g1 { ?a ?b ?c } GRAPH ?g2 { ?d ?e ?f } GRAPH ?g3 { ?h ?i ?j } } LIMIT 10" \
  "${END_USER_BASE_URL}sparql")
expected="$STATUS_OK"
echo "DEBUG: Expected: $expected"
echo "DEBUG: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"
