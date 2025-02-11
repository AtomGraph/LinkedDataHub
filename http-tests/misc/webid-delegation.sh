#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# check that the acl:delegates triple exists in the agent's description

get.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$AGENT_URI" \
| grep "<${SECRETARY_URI}> <http://www.w3.org/ns/auth/acl#delegates> <${AGENT_URI}>"

# agent not authorized - delegation should fail

curl --head -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$SECRETARY_CERT_FILE":"$SECRETARY_CERT_PWD" \
  -H "Accept: text/turtle" \
  -H "On-Behalf-Of: ${AGENT_URI}" \
  "$END_USER_BASE_URL" \
| grep -q "$STATUS_FORBIDDEN"

# add agent to the writers group to be able to read/write documents

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# agent authorized - delegation should succeed

curl --head -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$SECRETARY_CERT_FILE":"$SECRETARY_CERT_PWD" \
  -H "Accept: text/turtle" \
  -H "On-Behalf-Of: ${AGENT_URI}" \
  "$END_USER_BASE_URL" \
| grep -q "$STATUS_OK"
