#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A document's acl:owner and dct:creator are not the payload's to assert: a PUT that creates a document gets the
# requesting agent as both, and a PUT that replaces one keeps the stored values, whatever the payload says.

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

someone="http://example.com/someone#this"

# assert that a document has exactly one acl:owner and one dct:creator, the given agent

assert_ownership()
{
    local doc="$1" ntriples="$2" agent="$3" owners creators

    owners=$(echo "$ntriples" | grep "<${doc}> <http://www.w3.org/ns/auth/acl#owner> " || true)
    creators=$(echo "$ntriples" | grep "<${doc}> <http://purl.org/dc/terms/creator> " || true)
    echo "DEBUG: Expected owner and creator: <${agent}>"
    echo "DEBUG: Got owners: $owners"
    echo "DEBUG: Got creators: $creators"

    if [ "$owners" != "<${doc}> <http://www.w3.org/ns/auth/acl#owner> <${agent}> ." ]; then
        echo "DEBUG: unexpected acl:owner"
        exit 1
    fi
    if [ "$creators" != "<${doc}> <http://purl.org/dc/terms/creator> <${agent}> ." ]; then
        echo "DEBUG: unexpected dct:creator"
        exit 1
    fi
}

# create: the payload names another owner and creator, the agent becomes both

created="${END_USER_BASE_URL}put-acl-owner-created/"

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$created" <<EOF
<${created}> <http://purl.org/dc/terms/title> "Created" .
<${created}> <http://www.w3.org/ns/auth/acl#owner> <${someone}> .
<${created}> <http://purl.org/dc/terms/creator> <${someone}> .
EOF
)
expected="$STATUS_CREATED"
echo "DEBUG: PUT create: Expected: $expected"
echo "DEBUG: PUT create: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"

created_ntriples=$(ldh get \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$created")
echo "DEBUG: document after the PUT create: $created_ntriples"

assert_ownership "$created" "$created_ntriples" "$AGENT_URI"

# update: a document owned by the owner, replaced by the agent with itself as owner and creator

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Owned" \
  --slug "put-acl-owner-updated" \
  --container "$END_USER_BASE_URL")

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "If-Match: $(etag "$item" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")" \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF
<${item}> <http://purl.org/dc/terms/title> "Replaced" .
<${item}> <http://www.w3.org/ns/auth/acl#owner> <${AGENT_URI}> .
<${item}> <http://purl.org/dc/terms/creator> <${AGENT_URI}> .
EOF
)
expected="$STATUS_NO_CONTENT"
echo "DEBUG: PUT update: Expected: $expected"
echo "DEBUG: PUT update: Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"

item_ntriples=$(ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item")
echo "DEBUG: document after the PUT update: $item_ntriples"

# the replacement was written, the ownership was not

echo "$item_ntriples" | grep -q "<${item}> <http://purl.org/dc/terms/title> \"Replaced\""

assert_ownership "$item" "$item_ntriples" "$OWNER_URI"
