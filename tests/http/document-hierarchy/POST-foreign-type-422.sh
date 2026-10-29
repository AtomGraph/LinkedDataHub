#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A document is typed with the document hierarchy classes only: a POST whose payload types the document with any other
# class is refused with 422 and appends nothing.

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Typed" \
  --slug "post-foreign-type" \
  --container "$END_USER_BASE_URL")

# send a POST to the item as the owner and assert the status

post()
{
    local label="$1" expected="$2" payload="$3" actual

    actual=$(printf '%s\n' "$payload" | curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "If-Match: $(etag "$item" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")" \
      -H "Accept: application/n-triples" \
      -H "Content-Type: application/n-triples" \
      --data-binary @- \
      "$item")
    echo "DEBUG: ${label}: Expected: $expected"
    echo "DEBUG: ${label}: Got: $actual"
    [ "$actual" = "$expected" ] || exit 1
}

post "append another class" "$STATUS_UNPROCESSABLE_ENTITY" \
  "<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
<${item}> <http://purl.org/dc/terms/description> \"refused payload\" ."

item_ntriples=$(ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item")
types=$(echo "$item_ntriples" | grep -E "^<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " || true)
echo "DEBUG: Expected types: <${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> ."
echo "DEBUG: Got types: $types"
[ "$types" = "<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> ." ] || exit 1
if echo "$item_ntriples" | grep -q "refused payload"; then
    echo "DEBUG: the refused payload was appended"
    exit 1
fi

# another class on a resource in the document goes through

post "append another class on a resource in the document" "$STATUS_NO_CONTENT" \
  "<${item}#this> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> ."
