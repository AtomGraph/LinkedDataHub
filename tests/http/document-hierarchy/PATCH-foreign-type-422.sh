#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A document is typed with the document hierarchy classes only, and stays typed with one: a PATCH that adds any other
# class to the document, or swaps its hierarchy class for another, is refused with 422 and changes nothing.

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Typed" \
  --slug "patch-foreign-type" \
  --container "$END_USER_BASE_URL")

# send a PATCH as the owner and assert the status

patch()
{
    local label="$1" expected="$2" update="$3" actual

    actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -X PATCH \
      -H "If-Match: $(etag "$item" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")" \
      -H "Accept: application/n-triples" \
      -H "Content-Type: application/sparql-update" \
      --data-binary "$update" \
      "$item")
    echo "DEBUG: ${label}: Expected: $expected"
    echo "DEBUG: ${label}: Got: $actual"
    [ "$actual" = "$expected" ] || exit 1
}

# assert that the item is typed dh:Item and nothing else

assert_unchanged()
{
    local types

    types=$(ldh get \
      -c "$OWNER_CERT_KEYSTORE" \
      -p "$OWNER_CERT_PWD" \
      --accept 'application/n-triples' \
      "$item" \
      | grep -E "^<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " || true)
    echo "DEBUG: Expected types: <${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> ."
    echo "DEBUG: Got types: $types"
    [ "$types" = "<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> ." ] || exit 1
}

patch "add another class" "$STATUS_UNPROCESSABLE_ENTITY" \
  "INSERT { <${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> } WHERE {}"
assert_unchanged

patch "swap the hierarchy class for another" "$STATUS_UNPROCESSABLE_ENTITY" \
  "DELETE { <${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> } INSERT { <${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> } WHERE {}"
assert_unchanged

# another class on a resource in the document goes through

patch "add another class to a resource in the document" "$STATUS_NO_CONTENT" \
  "INSERT { <${item}#this> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> } WHERE {}"
