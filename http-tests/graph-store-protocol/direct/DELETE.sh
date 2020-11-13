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

# delete graph (of the Root document)

curl -k -w "%{http_code}\n" -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X DELETE \
  "${END_USER_BASE_URL}graphs/${graph_sha1}/" \
| grep -q "${STATUS_NO_CONTENT}"

# check that the graph is gone

curl -k -w "%{http_code}\n" -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}graphs/${graph_sha1}/" \
| grep -q "${STATUS_NOT_FOUND}"