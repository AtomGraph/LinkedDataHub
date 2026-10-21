#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# On a public dataspace anyone may POST to <sparql>, so that queries can go over POST: this is the grant that
# `ldh admin make-public` writes (acl:Append on <sparql> for foaf:Agent). An anonymous SPARQL Update passes the
# authorization and must still be refused by the endpoint with 405 - not 403, and not executed.

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Public SPARQL endpoint authorization" \
  --agent-class 'http://xmlns.com/foaf/0.1/Agent' \
  --to "${END_USER_BASE_URL}sparql" \
  --read \
  --append \
  "$ADMIN_BASE_URL"

# create a probe document

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Probe" \
  --slug "sparql-update-public-probe" \
  --container "$END_USER_BASE_URL")

update="INSERT DATA { GRAPH <${item}> { <${item}> <http://example.com/probe> \"updated\" } }"

# anonymous application/sparql-update body

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -X POST \
  -H "Content-Type: application/sparql-update" \
  -H "Accept: application/n-triples" \
  --data-binary "$update" \
  "${END_USER_BASE_URL}sparql")
expected="$STATUS_METHOD_NOT_ALLOWED"
echo "DEBUG: anonymous sparql-update body: Expected: $expected"
echo "DEBUG: anonymous sparql-update body: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"

# anonymous form update= parameter

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/n-triples" \
  --data-urlencode "update=${update}" \
  "${END_USER_BASE_URL}sparql")
expected="$STATUS_METHOD_NOT_ALLOWED"
echo "DEBUG: anonymous form update: Expected: $expected"
echo "DEBUG: anonymous form update: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"

# the probe document is unchanged

item_ntriples=$(ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item")
echo "DEBUG: probe document after the updates: $item_ntriples"

if echo "$item_ntriples" | grep -q "<http://example.com/probe>"; then
    echo "DEBUG: the probe document was changed by an anonymous SPARQL update on <sparql>"
    exit 1
fi

# an anonymous query over POST still works

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/sparql-results+xml" \
  --data-urlencode "query=ASK { ?s ?p ?o }" \
  "${END_USER_BASE_URL}sparql")
expected="$STATUS_OK"
echo "DEBUG: anonymous form query: Expected: $expected"
echo "DEBUG: anonymous form query: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"
