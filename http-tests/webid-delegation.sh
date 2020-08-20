#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

container_id=$(docker ps -a -q  --filter ancestor=atomgraph/linkeddatahub)
SECRETARY_REL_URI=$(docker exec "$container_id" bash -c 'echo "$SECRETARY_REL_URI"')
SECRETARY_URI="${END_USER_BASE_URL}${SECRETARY_REL_URI}"

pushd . > /dev/null && cd "$SCRIPT_ROOT"

# check that the acl:delegates triple exists in the agent's description

./get-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "${AGENT_URI}" \
| grep "<${SECRETARY_URI}> <http://www.w3.org/ns/auth/acl#delegates> <${AGENT_URI}>"

popd

# agent not authorized - delegation should fail

curl --head -k -w "%{http_code}\n" -f -v \
  -E "$SECRETARY_CERT_FILE":"$SECRETARY_CERT_PWD" \
  -H "Accept: text/turtle" \
  -H "On-Behalf-Of: ${AGENT_URI}" \
  "$END_USER_BASE_URL" \
| grep -q "${STATUS_FORBIDDEN}"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group to be able to read/write documents (might already be done by another test)

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

# agent authorized - delegation should succeed

curl --head -k -w "%{http_code}\n" -f -v \
  -E "$SECRETARY_CERT_FILE":"$SECRETARY_CERT_PWD" \
  -H "Accept: text/turtle" \
  -H "On-Behalf-Of: ${AGENT_URI}" \
  "$END_USER_BASE_URL" \
| grep -q "${STATUS_OK}"
