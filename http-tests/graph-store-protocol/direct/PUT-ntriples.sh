#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group to be able to read/write documents

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

graph_sha1=$(echo "$END_USER_BASE_URL" | sha1sum | cut -d " " -f 1)

# replace the named graph

(
curl -k -w "%{http_code}\n" -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "${END_USER_BASE_URL}graphs/${graph_sha1}/" <<EOF
<${END_USER_BASE_URL}named-subject-put> <http://example.com/default-predicate> "named object PUT" .
<${END_USER_BASE_URL}named-subject-put> <http://example.com/another-predicate> "another named object PUT" .
EOF
) \
| grep -q "${STATUS_OK}"

# check that resource is accessible

curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}graphs/${graph_sha1}/" \
| tr -d '\n' \
| grep '"named object PUT"' \
| grep -v '"named object"' > /dev/null