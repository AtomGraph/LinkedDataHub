#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A document's graph states the containment of that document only: a PUT whose payload gives sioc:has_parent or
# sioc:has_container to any other resource is refused with 422, whether it replaces a document or creates one, and
# writes nothing.

container=$(ldh create container \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Other" \
  --slug "other" \
  --parent "$END_USER_BASE_URL")

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Writer" \
  --slug "put-foreign-containment" \
  --container "$END_USER_BASE_URL")

other=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Described" \
  --slug "put-foreign-containment-other" \
  --container "$END_USER_BASE_URL")

# send a PUT as the owner and assert the status: a replace quotes the document's tag, a create asks for none

put()
{
    local label="$1" expected="$2" document="$3" payload="$4" precondition actual

    if [ "$document" = "$item" ]; then
        precondition="If-Match: $(etag "$item" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")"
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

put "replace with containment of another document" "$STATUS_UNPROCESSABLE_ENTITY" "$item" \
  "<${item}> <http://purl.org/dc/terms/title> \"Replaced\" .
<${other}> <http://rdfs.org/sioc/ns#has_parent> <${container}> ."

put "replace with containment of a resource in the document" "$STATUS_UNPROCESSABLE_ENTITY" "$item" \
  "<${item}> <http://purl.org/dc/terms/title> \"Replaced\" .
<${item}#thing> <http://rdfs.org/sioc/ns#has_container> <${container}> ."

item_ntriples=$(ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item")
title=$(echo "$item_ntriples" | grep -E "^<${item}> <http://purl.org/dc/terms/title> " || true)
echo "DEBUG: Expected title: <${item}> <http://purl.org/dc/terms/title> \"Writer\" ."
echo "DEBUG: Got title: $title"
[ "$title" = "<${item}> <http://purl.org/dc/terms/title> \"Writer\" ." ] || exit 1

# creating a document

created="${END_USER_BASE_URL}$(uuidgen | tr '[:upper:]' '[:lower:]')/"

put "create with containment of another document" "$STATUS_UNPROCESSABLE_ENTITY" "$created" \
  "<${created}> <http://purl.org/dc/terms/title> \"Created\" .
<${other}> <http://rdfs.org/sioc/ns#has_container> <${container}> ."

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$created")
echo "DEBUG: the refused document. Expected: $STATUS_FORBIDDEN Got: $status"
[ "$status" = "$STATUS_FORBIDDEN" ] || exit 1

# a payload with no containment of another resource goes through; the document's own is replaced by the server's

put "replace without foreign containment" "$STATUS_NO_CONTENT" "$item" \
  "<${item}> <http://purl.org/dc/terms/title> \"Replaced\" .
<${item}> <http://rdfs.org/sioc/ns#has_container> <${container}> ."
