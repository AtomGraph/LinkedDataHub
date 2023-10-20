#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

pushd . > /dev/null && cd "$SCRIPT_ROOT"

# create item

slug="test-item"

item=$(./create-item.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test" \
  --slug "$slug" \
  --container "$END_USER_BASE_URL")

popd > /dev/null

# check that item as parent is forbidden

(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -X PUT \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Content-Type: application/n-triples" \
   --data-binary @- \
  "${item}child/" <<EOF
<http://s> <http://p> <http://o> .
EOF
) \
| grep -q "$STATUS_FORBIDDEN"