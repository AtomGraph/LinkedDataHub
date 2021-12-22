#!/bin/bash
set -e

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pwd=$(realpath -s "$PWD")

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group to be able to read/write documents (might already be done by another test)

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

file="$(mktemp)"
truncate -s 3M "${file}" # assuming MAX_CONTENT_LENGTH is set to 2MB
file_content_type="text/plain" # content type doesn't matter -- only Content-Length

curl -w "%{http_code}\n" -k -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Content-Type: ${file_content_type}" \
  -H "Accept: text/turtle" \
  --data-binary "@${file}" \
  "${END_USER_BASE_URL}" \
| grep -q "${STATUS_REQUEST_ENTITY_TOO_LARGE}"