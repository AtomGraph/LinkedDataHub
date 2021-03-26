#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group to be able to read/write documents

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

graph_sha1=$(echo -n "$END_USER_BASE_URL" | sha1sum | cut -d " " -f 1)

# GET the directly identified named graph
# request N-Triples twice - supply ETag second time and expect 303 Not Modified

etag=$(
curl -k -f -s -I -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}graphs/${graph_sha1}/" \
| grep 'ETag' \
| sed -En 's/^ETag: (.*)/\1/p')

curl -k -w "%{http_code}\n" -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}graphs/${graph_sha1}/" \
  -H "If-None-Match: $etag" \
| grep -q "${STATUS_NOT_MODIFIED}"