#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the writers group

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create a new document with PUT to establish initial state

slug="post-metadata-test-item"
item="${END_USER_BASE_URL}${slug}/"

(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF
<${item}> <http://purl.org/dc/terms/title> "POST Metadata Test Item" .
<${item}> <http://example.com/initial-predicate> "initial value" .
EOF
) \
| grep -q "$STATUS_CREATED"

# get initial state and verify cardinalities after PUT

item_ntriples=$(get.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item"
 )

# check that exactly one dct:created exists and no dct:modified yet
created_count=$(echo "$item_ntriples" | grep -c "<${item}> <http://purl.org/dc/terms/created> " || true)
if [ "$created_count" -ne 1 ]; then
    echo "Expected exactly 1 dct:created property after creation, found $created_count"
    exit 1
fi

modified_count=$(echo "$item_ntriples" | grep -c "<${item}> <http://purl.org/dc/terms/modified> " || true)
if [ "$modified_count" -ne 0 ]; then
    echo "Expected no dct:modified property after creation, found $modified_count"
    exit 1
fi

# perform first POST operation

(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF
<${item}> <http://example.com/post-predicate-1> "first POST value" .
EOF
) \
| grep -q "$STATUS_NO_CONTENT"

# get state after first POST and verify cardinalities

item_ntriples=$(get.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item"
 )

# check that exactly one dct:created and one dct:modified exist
created_count=$(echo "$item_ntriples" | grep -c "<${item}> <http://purl.org/dc/terms/created> " || true)
if [ "$created_count" -ne 1 ]; then
    echo "Expected exactly 1 dct:created property after first POST, found $created_count"
    exit 1
fi

modified_count=$(echo "$item_ntriples" | grep -c "<${item}> <http://purl.org/dc/terms/modified> " || true)
if [ "$modified_count" -ne 1 ]; then
    echo "Expected exactly 1 dct:modified property after first POST, found $modified_count"
    exit 1
fi

# perform second POST operation (this is the key test for accumulation bug)

(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF
<${item}> <http://example.com/post-predicate-2> "second POST value" .
EOF
) \
| grep -q "$STATUS_NO_CONTENT"

# get final state and verify cardinalities (key test for the fix)

item_ntriples=$(get.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item"
 )

# check that exactly one dct:created and one dct:modified still exist
created_count=$(echo "$item_ntriples" | grep -c "<${item}> <http://purl.org/dc/terms/created> " || true)
if [ "$created_count" -ne 1 ]; then
    echo "Expected exactly 1 dct:created property after second POST, found $created_count"
    exit 1
fi

modified_count=$(echo "$item_ntriples" | grep -c "<${item}> <http://purl.org/dc/terms/modified> " || true)
if [ "$modified_count" -ne 1 ]; then
    echo "Expected exactly 1 dct:modified property after second POST, found $modified_count"
    echo "This indicates the fix for accumulating dct:modified values in Graph::post() is not working"
    exit 1
fi

# verify that all POST content was added (ensure POST operations work correctly)
echo "$item_ntriples" | grep "\"first POST value\"" > /dev/null
echo "$item_ntriples" | grep "\"second POST value\"" > /dev/null