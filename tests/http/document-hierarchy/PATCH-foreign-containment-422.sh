#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A document's graph states the containment of that document only: a PATCH that inserts sioc:has_parent or
# sioc:has_container of any other resource is refused with 422 and changes nothing.

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
  --slug "patch-foreign-containment" \
  --container "$END_USER_BASE_URL")

other=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Described" \
  --slug "patch-foreign-containment-other" \
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

# assert that the item's graph holds no containment but its own, and that its title is unchanged

assert_unchanged()
{
    local item_ntriples foreign title

    item_ntriples=$(ldh get \
      -c "$OWNER_CERT_KEYSTORE" \
      -p "$OWNER_CERT_PWD" \
      --accept 'application/n-triples' \
      "$item")
    foreign=$(echo "$item_ntriples" | grep -E "<http://rdfs.org/sioc/ns#has_(parent|container)> " | grep -vE "^<${item}> " || true)
    echo "DEBUG: Expected foreign containment: (none)"
    echo "DEBUG: Got foreign containment: $foreign"
    [ -z "$foreign" ] || exit 1

    title=$(echo "$item_ntriples" | grep -E "^<${item}> <http://purl.org/dc/terms/title> " || true)
    echo "DEBUG: Expected title: <${item}> <http://purl.org/dc/terms/title> \"Writer\" ."
    echo "DEBUG: Got title: $title"
    [ "$title" = "<${item}> <http://purl.org/dc/terms/title> \"Writer\" ." ] || exit 1
}

patch "insert containment of another document" "$STATUS_UNPROCESSABLE_ENTITY" \
  "DELETE { <${item}> <http://purl.org/dc/terms/title> ?title } INSERT { <${item}> <http://purl.org/dc/terms/title> \"Renamed\" . <${other}> <http://rdfs.org/sioc/ns#has_container> <${container}> } WHERE { <${item}> <http://purl.org/dc/terms/title> ?title }"
assert_unchanged

patch "insert a parent of a resource in the document" "$STATUS_UNPROCESSABLE_ENTITY" \
  "INSERT { <${item}#thing> <http://rdfs.org/sioc/ns#has_parent> <${container}> } WHERE {}"
assert_unchanged

patch "insert containment of a blank node" "$STATUS_UNPROCESSABLE_ENTITY" \
  "INSERT { _:thing <http://rdfs.org/sioc/ns#has_parent> <${container}> } WHERE {}"
assert_unchanged

# an update with no containment of another resource goes through

patch "change the title" "$STATUS_NO_CONTENT" \
  "DELETE { <${item}> <http://purl.org/dc/terms/title> ?title } INSERT { <${item}> <http://purl.org/dc/terms/title> \"Renamed\" } WHERE { <${item}> <http://purl.org/dc/terms/title> ?title }"
