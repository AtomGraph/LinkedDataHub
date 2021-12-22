#!/bin/bash
set -euxo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

# attempt to create a new named graph using direct identification fails due to missing authorizations
# the current W3C ACL ontology-based model does not support "unknown" URIs that are not attached to any acl:Authorization using acl:accessTo or acl:accessToClass

curl -k -w "%{http_code}\n" -f -s \
  -X PUT \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Content-Type: application/n-triples" \
  "${END_USER_BASE_URL}non-existing/" \
| grep -q "$STATUS_FORBIDDEN"