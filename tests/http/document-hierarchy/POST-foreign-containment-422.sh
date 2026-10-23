#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A document's graph states the containment of that document only: a POST whose payload gives sioc:has_parent or
# sioc:has_container to any other resource is refused with 422 and appends nothing. A union-graph containment path
# would otherwise read it as the other resource's place in the hierarchy.

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
  --slug "post-foreign-containment" \
  --container "$END_USER_BASE_URL")

other=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Described" \
  --slug "post-foreign-containment-other" \
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

# assert that the item's graph holds no containment but its own, and none of the refused payload

assert_nothing_appended()
{
    local item_ntriples foreign

    item_ntriples=$(ldh get \
      -c "$OWNER_CERT_KEYSTORE" \
      -p "$OWNER_CERT_PWD" \
      --accept 'application/n-triples' \
      "$item")
    foreign=$(echo "$item_ntriples" | grep -E "<http://rdfs.org/sioc/ns#has_(parent|container)> " | grep -vE "^<${item}> " || true)
    echo "DEBUG: Expected foreign containment: (none)"
    echo "DEBUG: Got foreign containment: $foreign"
    [ -z "$foreign" ] || exit 1

    if echo "$item_ntriples" | grep -q "refused payload"; then
        echo "DEBUG: the refused payload was appended"
        exit 1
    fi
}

post "containment of another document" "$STATUS_UNPROCESSABLE_ENTITY" \
  "<${other}> <http://rdfs.org/sioc/ns#has_container> <${container}> .
<${item}> <http://example.com/default-predicate> \"refused payload\" ."
assert_nothing_appended

post "a parent of another document" "$STATUS_UNPROCESSABLE_ENTITY" \
  "<${other}> <http://rdfs.org/sioc/ns#has_parent> <${container}> ."
assert_nothing_appended

post "containment of a resource in the document" "$STATUS_UNPROCESSABLE_ENTITY" \
  "<${item}#thing> <http://rdfs.org/sioc/ns#has_container> <${container}> .
<${item}> <http://example.com/default-predicate> \"refused payload\" ."
assert_nothing_appended

post "containment of a blank node" "$STATUS_UNPROCESSABLE_ENTITY" \
  "_:thing <http://rdfs.org/sioc/ns#has_parent> <${container}> ."
assert_nothing_appended

# the other document is where its own graph puts it

other_ntriples=$(ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$other")
containment=$(echo "$other_ntriples" | grep -E "^<${other}> <http://rdfs.org/sioc/ns#has_(parent|container)> " || true)
echo "DEBUG: Expected containment: <${other}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}> ."
echo "DEBUG: Got containment: $containment"
[ "$containment" = "<${other}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}> ." ] || exit 1

# a payload with no containment of another resource goes through

post "no foreign containment" "$STATUS_NO_CONTENT" \
  "<${item}> <http://example.com/default-predicate> \"appended\" ."
