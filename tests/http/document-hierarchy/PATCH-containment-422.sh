#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A PATCH whose result changes the document's sioc:has_parent or sioc:has_container is refused with 422 and changes
# nothing: a document's place in the hierarchy is the URI parent PUT points it at. A PATCH that leaves it alone goes
# through.

container=$(ldh create container \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Other" \
  --slug "other" \
  --parent "$END_USER_BASE_URL")

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Contained" \
  --slug "patch-containment" \
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

# assert that the document is still contained in the root, and only there

assert_containment_unchanged()
{
    local item_ntriples containment

    item_ntriples=$(ldh get \
      -c "$OWNER_CERT_KEYSTORE" \
      -p "$OWNER_CERT_PWD" \
      --accept 'application/n-triples' \
      "$item")
    containment=$(echo "$item_ntriples" | grep -E "^<${item}> <http://rdfs.org/sioc/ns#has_(parent|container)> " || true)
    echo "DEBUG: Expected containment: <${item}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}> ."
    echo "DEBUG: Got containment: $containment"

    [ "$containment" = "<${item}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}> ." ] || exit 1
}

patch "move to another container" "$STATUS_UNPROCESSABLE_ENTITY" \
  "DELETE { <${item}> <http://rdfs.org/sioc/ns#has_container> ?c } INSERT { <${item}> <http://rdfs.org/sioc/ns#has_container> <${container}> } WHERE { <${item}> <http://rdfs.org/sioc/ns#has_container> ?c }"
assert_containment_unchanged

patch "add a second container" "$STATUS_UNPROCESSABLE_ENTITY" \
  "INSERT { <${item}> <http://rdfs.org/sioc/ns#has_container> <${container}> } WHERE {}"
assert_containment_unchanged

patch "remove the container" "$STATUS_UNPROCESSABLE_ENTITY" \
  "DELETE WHERE { <${item}> <http://rdfs.org/sioc/ns#has_container> ?c }"
assert_containment_unchanged

patch "add a parent" "$STATUS_UNPROCESSABLE_ENTITY" \
  "INSERT { <${item}> <http://rdfs.org/sioc/ns#has_parent> <${container}> } WHERE {}"
assert_containment_unchanged

# a PATCH that leaves the containment alone goes through

patch "change the title" "$STATUS_NO_CONTENT" \
  "DELETE { <${item}> <http://purl.org/dc/terms/title> ?title } INSERT { <${item}> <http://purl.org/dc/terms/title> \"Renamed\" } WHERE { <${item}> <http://purl.org/dc/terms/title> ?title }"
assert_containment_unchanged
