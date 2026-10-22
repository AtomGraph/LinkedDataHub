#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A PATCH whose result changes the document's acl:owner or dct:creator is refused with 422 and changes nothing.
# It is refused for everyone, the owner included: ownership changes go through the admin ACL documents. A PATCH
# that leaves them alone goes through.

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create a document owned by the owner

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Owned" \
  --slug "patch-acl-owner" \
  --container "$END_USER_BASE_URL")

# send a PATCH as the given agent and assert the status

patch()
{
    local label="$1" cert_file="$2" cert_pwd="$3" expected="$4" update="$5" actual

    actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$cert_file":"$cert_pwd" \
      -X PATCH \
      -H "If-Match: $(etag "$item" "$cert_file" "$cert_pwd" "application/n-triples")" \
      -H "Accept: application/n-triples" \
      -H "Content-Type: application/sparql-update" \
      --data-binary "$update" \
      "$item")
    echo "DEBUG: ${label}: Expected: $expected"
    echo "DEBUG: ${label}: Got: $actual"
    echo "$actual" | grep -qE "^(${expected})$"
}

# assert that the document still has exactly one acl:owner and one dct:creator, the owner

assert_ownership_unchanged()
{
    local item_ntriples owners creators

    item_ntriples=$(ldh get \
      -c "$OWNER_CERT_KEYSTORE" \
      -p "$OWNER_CERT_PWD" \
      --accept 'application/n-triples' \
      "$item")
    owners=$(echo "$item_ntriples" | grep "<${item}> <http://www.w3.org/ns/auth/acl#owner> " || true)
    creators=$(echo "$item_ntriples" | grep "<${item}> <http://purl.org/dc/terms/creator> " || true)
    echo "DEBUG: Expected owner and creator: <${OWNER_URI}>"
    echo "DEBUG: Got owners: $owners"
    echo "DEBUG: Got creators: $creators"

    if [ "$owners" != "<${item}> <http://www.w3.org/ns/auth/acl#owner> <${OWNER_URI}> ." ]; then
        echo "DEBUG: acl:owner changed"
        exit 1
    fi
    if [ "$creators" != "<${item}> <http://purl.org/dc/terms/creator> <${OWNER_URI}> ." ]; then
        echo "DEBUG: dct:creator changed"
        exit 1
    fi
}

# the writer adds itself as an owner

patch "writer inserts acl:owner" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "$STATUS_UNPROCESSABLE_ENTITY" \
  "INSERT { <${item}> <http://www.w3.org/ns/auth/acl#owner> <${AGENT_URI}> } WHERE {}"
assert_ownership_unchanged

# the writer replaces the owner

patch "writer replaces acl:owner" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "$STATUS_UNPROCESSABLE_ENTITY" \
  "DELETE { <${item}> <http://www.w3.org/ns/auth/acl#owner> ?owner } INSERT { <${item}> <http://www.w3.org/ns/auth/acl#owner> <${AGENT_URI}> } WHERE { <${item}> <http://www.w3.org/ns/auth/acl#owner> ?owner }"
assert_ownership_unchanged

# the writer removes the creator

patch "writer deletes dct:creator" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "$STATUS_UNPROCESSABLE_ENTITY" \
  "DELETE WHERE { <${item}> <http://purl.org/dc/terms/creator> ?creator }"
assert_ownership_unchanged

# the owner adds the writer as a co-owner: refused too

patch "owner inserts acl:owner" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "$STATUS_UNPROCESSABLE_ENTITY" \
  "INSERT { <${item}> <http://www.w3.org/ns/auth/acl#owner> <${AGENT_URI}> } WHERE {}"
assert_ownership_unchanged

# a PATCH that leaves the ownership alone goes through

patch "writer changes the title" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "$STATUS_NO_CONTENT" \
  "DELETE { <${item}> <http://purl.org/dc/terms/title> ?title } INSERT { <${item}> <http://purl.org/dc/terms/title> \"Renamed\" } WHERE { <${item}> <http://purl.org/dc/terms/title> ?title }"
assert_ownership_unchanged

ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item" \
| grep -q "<${item}> <http://purl.org/dc/terms/title> \"Renamed\""
