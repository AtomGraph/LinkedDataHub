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

# store the ETag value

etag_before=$(
  curl -k -i -f -s -G \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| grep 'ETag' \
| tr -d '\r' \
| sed -En 's/^ETag: (.*)$/\1/p')

# append to the graph only if the ETag value matches

(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-Match: ${etag_before}" \
  --data-binary @- \
  "$END_USER_BASE_URL" <<EOF
<${END_USER_BASE_URL}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/default#Root> .
<${END_USER_BASE_URL}> <http://purl.org/dc/terms/title> "Root" .
<${END_USER_BASE_URL}named-subject-put> <http://example.com/default-predicate> "named object PUT" .
<${END_USER_BASE_URL}named-subject-put> <http://example.com/another-predicate> "another named object PUT" .
EOF
) \
| grep -q "$STATUS_NO_CONTENT"
