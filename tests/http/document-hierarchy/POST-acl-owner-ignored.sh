#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A POST appends to a document, and the document's acl:owner and dct:creator are not the payload's to assert: the
# server drops them from the payload and keeps the stored ones. The agent gets Read and Append on the document
# alone rather than joining the writers group: writers can write any document anyway, so only an agent without
# Write can show that appending ownership grants nothing - its PUT and DELETE stay 403 afterwards.

# create a document owned by the owner

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Owned" \
  --slug "post-acl-owner" \
  --container "$END_USER_BASE_URL")

# let the agent read and append to it

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Append to the owned document" \
  --agent "$AGENT_URI" \
  --to "$item" \
  --read \
  --append \
  "$ADMIN_BASE_URL"

# append ownership of the document, along with an ordinary triple

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "If-Match: $(etag "$item" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")" \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF
<${item}> <http://www.w3.org/ns/auth/acl#owner> <${AGENT_URI}> .
<${item}> <http://purl.org/dc/terms/creator> <${AGENT_URI}> .
<${item}> <http://example.com/default-predicate> "named object POST" .
EOF
)
expected="$STATUS_NO_CONTENT"
echo "DEBUG: POST: Expected: $expected"
echo "DEBUG: POST: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"

item_ntriples=$(ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item")
echo "DEBUG: document after the POST: $item_ntriples"

# the ordinary triple was appended

echo "$item_ntriples" | grep -q "<${item}> <http://example.com/default-predicate> \"named object POST\""

# the owner is still the only owner and creator

owners=$(echo "$item_ntriples" | grep "<${item}> <http://www.w3.org/ns/auth/acl#owner> " || true)
creators=$(echo "$item_ntriples" | grep "<${item}> <http://purl.org/dc/terms/creator> " || true)
echo "DEBUG: Expected owner and creator: <${OWNER_URI}>"
echo "DEBUG: Got owners: $owners"
echo "DEBUG: Got creators: $creators"

if [ "$owners" != "<${item}> <http://www.w3.org/ns/auth/acl#owner> <${OWNER_URI}> ." ]; then
    echo "DEBUG: acl:owner changed by the POST"
    exit 1
fi
if [ "$creators" != "<${item}> <http://purl.org/dc/terms/creator> <${OWNER_URI}> ." ]; then
    echo "DEBUG: dct:creator changed by the POST"
    exit 1
fi

# the agent gained no ownership: writing and deleting the document stay forbidden

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF
<${item}> <http://purl.org/dc/terms/title> "Taken" .
EOF
)
expected="$STATUS_FORBIDDEN"
echo "DEBUG: PUT after POST: Expected: $expected"
echo "DEBUG: PUT after POST: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X DELETE \
  -H "Accept: application/n-triples" \
  "$item")
expected="$STATUS_FORBIDDEN"
echo "DEBUG: DELETE after POST: Expected: $expected"
echo "DEBUG: DELETE after POST: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"
