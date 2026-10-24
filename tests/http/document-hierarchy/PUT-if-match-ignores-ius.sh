#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# RFC 9110 13.2.2: when If-Match is present, If-Unmodified-Since is not evaluated. A PUT quoting the current tag
# succeeds whatever date it also sends - here one long before the document was last modified

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

etag=$(etag "$END_USER_BASE_URL" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")

status=$(
curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-Match: ${etag}" \
  -H "If-Unmodified-Since: Mon, 01 Jan 2001 00:00:00 GMT" \
  --data-binary @- \
  "$END_USER_BASE_URL" <<EOF
<${END_USER_BASE_URL}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/default#Root> .
<${END_USER_BASE_URL}> <http://purl.org/dc/terms/title> "Root" .
EOF
)

echo "DEBUG: If-Match: $etag  Expected: $STATUS_NO_CONTENT  Got: $status"
[ "$status" = "$STATUS_NO_CONTENT" ]
