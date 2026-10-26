#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A document is typed with the document hierarchy classes only: a PUT whose payload types the document with any other
# class is refused with 422, whether it replaces a document or creates one, and writes nothing. The root, which is
# stored as sent, must be typed with one of them. A class grant matches a document's types, so this is what keeps a
# grant of any other class away from the documents.

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Typed" \
  --slug "put-foreign-type" \
  --container "$END_USER_BASE_URL")

# send a PUT as the owner and assert the status: a replace quotes the document's tag, a create asks for none

put()
{
    local label="$1" expected="$2" document="$3" payload="$4" precondition actual

    if [ "$document" = "$item" ] || [ "$document" = "$END_USER_BASE_URL" ]; then
        precondition="If-Match: $(etag "$document" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")"
    else
        precondition="If-None-Match: *"
    fi

    actual=$(printf '%s\n' "$payload" | curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -X PUT \
      -H "$precondition" \
      -H "Accept: application/n-triples" \
      -H "Content-Type: application/n-triples" \
      --data-binary @- \
      "$document")
    echo "DEBUG: ${label}: Expected: $expected"
    echo "DEBUG: ${label}: Got: $actual"
    [ "$actual" = "$expected" ] || exit 1
}

# replacing a document

put "replace with another class" "$STATUS_UNPROCESSABLE_ENTITY" "$item" \
  "<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .
<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
<${item}> <http://purl.org/dc/terms/title> \"Replaced\" ."

item_ntriples=$(ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item")
title=$(echo "$item_ntriples" | grep -E "^<${item}> <http://purl.org/dc/terms/title> " || true)
echo "DEBUG: Expected title: <${item}> <http://purl.org/dc/terms/title> \"Typed\" ."
echo "DEBUG: Got title: $title"
[ "$title" = "<${item}> <http://purl.org/dc/terms/title> \"Typed\" ." ] || exit 1

# creating a document

created="${END_USER_BASE_URL}$(uuidgen | tr '[:upper:]' '[:lower:]')/"

put "create with another class" "$STATUS_UNPROCESSABLE_ENTITY" "$created" \
  "<${created}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
<${created}> <http://purl.org/dc/terms/title> \"Created\" ."

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$created")
echo "DEBUG: the refused document. Expected: $STATUS_FORBIDDEN Got: $status"
[ "$status" = "$STATUS_FORBIDDEN" ] || exit 1

# the root without its hierarchy class

root_ntriples=$(ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$END_USER_BASE_URL")
untyped_root=$(echo "$root_ntriples" | grep -vE "^<${END_USER_BASE_URL}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ")

put "replace the root untyped" "$STATUS_UNPROCESSABLE_ENTITY" "$END_USER_BASE_URL" "$untyped_root"
put "replace the root as it is" "$STATUS_NO_CONTENT" "$END_USER_BASE_URL" "$root_ntriples"

# another class on a resource in the document goes through

put "replace with another class on a resource in the document" "$STATUS_NO_CONTENT" "$item" \
  "<${item}> <http://purl.org/dc/terms/title> \"Replaced\" .
<${item}> <http://xmlns.com/foaf/0.1/primaryTopic> <${item}#this> .
<${item}#this> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> ."
