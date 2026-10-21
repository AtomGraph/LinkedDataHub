#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# The <sparql> endpoint answers queries only: writes go through the Graph Store Protocol, where they are authorized
# per document. SPARQL Update is refused with 405 - as a sparql-update body and as a form update= parameter - even
# for the owner, and the store is left as it was.
# TO-DO: assert "Allow: GET, POST" once Web-Client's ClientErrorExceptionMapper keeps the exception's headers

# create a probe document

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Probe" \
  --slug "sparql-update-probe" \
  --container "$END_USER_BASE_URL")

update="INSERT DATA { GRAPH <${item}> { <${item}> <http://example.com/probe> \"updated\" } }"

# application/sparql-update body

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/sparql-update" \
  -H "Accept: application/n-triples" \
  --data-binary "$update" \
  "${END_USER_BASE_URL}sparql")
expected="$STATUS_METHOD_NOT_ALLOWED"
echo "DEBUG: sparql-update body: Expected: $expected"
echo "DEBUG: sparql-update body: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"

# form update= parameter

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/n-triples" \
  --data-urlencode "update=${update}" \
  "${END_USER_BASE_URL}sparql")
expected="$STATUS_METHOD_NOT_ALLOWED"
echo "DEBUG: form update: Expected: $expected"
echo "DEBUG: form update: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"

# the probe document is unchanged

item_ntriples=$(ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item")
echo "DEBUG: probe document after the updates: $item_ntriples"

if echo "$item_ntriples" | grep -q "<http://example.com/probe>"; then
    echo "DEBUG: the probe document was changed by a SPARQL update on <sparql>"
    exit 1
fi
echo "$item_ntriples" | grep -q "<${item}> <http://purl.org/dc/terms/title> \"Probe\""

# a query over POST still works, as a form and as a sparql-query body

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/sparql-results+xml" \
  --data-urlencode "query=ASK { ?s ?p ?o }" \
  "${END_USER_BASE_URL}sparql")
expected="$STATUS_OK"
echo "DEBUG: form query: Expected: $expected"
echo "DEBUG: form query: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/sparql-query" \
  -H "Accept: application/sparql-results+xml" \
  --data-binary "ASK { ?s ?p ?o }" \
  "${END_USER_BASE_URL}sparql")
expected="$STATUS_OK"
echo "DEBUG: sparql-query body: Expected: $expected"
echo "DEBUG: sparql-query body: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"
