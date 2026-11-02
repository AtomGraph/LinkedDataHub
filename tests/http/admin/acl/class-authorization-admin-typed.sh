#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A class grant reaches a document through the classes the document's own graph types it with. Admin documents are
# typed with the document hierarchy classes only, which no authorization may name, so a grant of any other class -
# scoped to the end-user dataspace - reaches none of them: a write that would type an admin document with the granted
# class is refused with 422, even from the owner, and the grantee is still denied.

class="http://xmlns.com/foaf/0.1/Person"
document="${ADMIN_BASE_URL}acl/groups/writers/"

get_status()
{
  curl -k -w "%{http_code}" -o /dev/null -s \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -H "Accept: application/n-triples" \
    "$document"
}

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Read access to a class" \
  --agent "$AGENT_URI" \
  --to-all-in "$class" \
  --read \
  "$ADMIN_BASE_URL" > /dev/null

status=$(get_status)
echo "DEBUG: <$document> before. Expected: $STATUS_FORBIDDEN Got: $status"
[ "$status" = "$STATUS_FORBIDDEN" ] || exit 1

# send a write as the owner and assert the status

write()
{
    local label="$1" expected="$2" method="$3" content_type="$4" body="$5" actual

    actual=$(printf '%s\n' "$body" | curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -X "$method" \
      -H "If-Match: $(etag "$document" "$OWNER_CERT_FILE" "$OWNER_CERT_PWD" "application/n-triples")" \
      -H "Accept: application/n-triples" \
      -H "Content-Type: $content_type" \
      --data-binary @- \
      "$document")
    echo "DEBUG: ${label}: Expected: $expected"
    echo "DEBUG: ${label}: Got: $actual"
    [ "$actual" = "$expected" ] || exit 1
}

write "POST the granted class" "$STATUS_UNPROCESSABLE_ENTITY" POST "application/n-triples" \
  "<${document}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <${class}> ."

write "PATCH in the granted class" "$STATUS_UNPROCESSABLE_ENTITY" PATCH "application/sparql-update" \
  "INSERT { <${document}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <${class}> } WHERE {}"

group_ntriples=$(ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$document")
write "PUT with the granted class" "$STATUS_UNPROCESSABLE_ENTITY" PUT "application/n-triples" \
  "$(printf '%s\n<%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <%s> .' "$group_ntriples" "$document" "$class")"

status=$(get_status)
echo "DEBUG: <$document> after. Expected: $STATUS_FORBIDDEN Got: $status"
[ "$status" = "$STATUS_FORBIDDEN" ] || exit 1
