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

# check that a 201 response to a new document includes a Location header matching the request URI

new_doc_uri="${END_USER_BASE_URL}$(uuidgen | tr '[:upper:]' '[:lower:]')/"

response=$(curl -k -s \
  -X PUT \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Content-Type: application/n-triples" \
  -D - \
  -o /dev/null \
  --data-binary @- \
  "$new_doc_uri" <<EOF
EOF
)

http_code=$(echo "$response" | grep -m1 "^HTTP" | awk '{print $2}')
location=$(echo "$response" | grep -i "^location:" | tr -d '\r' | awk '{print $2}')

[ "$http_code" = "$STATUS_CREATED" ]
[ "$location" = "$new_doc_uri" ]
