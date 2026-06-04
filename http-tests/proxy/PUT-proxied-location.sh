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

# Regression: ProxyRequestFilter.getResponse() returned early without forwarding headers when
# the upstream returned no Content-Type (e.g. 201 Created with empty body). This stripped the
# Location header from 201 responses, so the client-side XSLT could not navigate to the new doc.

new_doc_uri="${END_USER_BASE_URL}$(uuidgen | tr '[:upper:]' '[:lower:]')/"

response=$(curl -k -s \
  -X PUT \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Content-Type: application/n-triples" \
  -H "Accept: application/rdf+xml" \
  -D - \
  -o /dev/null \
  --data-binary @- \
  --url-query "uri=${new_doc_uri}" \
  "$END_USER_BASE_URL" <<EOF
EOF
)

http_code=$(echo "$response" | grep -m1 "^HTTP" | awk '{print $2}')
location=$(echo "$response" | grep -i "^location:" | tr -d '\r' | awk '{print $2}')

[ "$http_code" = "$STATUS_CREATED" ]
[ "$location" = "$new_doc_uri" ]
