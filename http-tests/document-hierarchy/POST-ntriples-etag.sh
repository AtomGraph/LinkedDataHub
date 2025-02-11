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

# create public authorization

create-authorization.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --label "Public access authorization" \
  --agent-class 'http://xmlns.com/foaf/0.1/Agent' \
  --to "$END_USER_BASE_URL" \
  --read

etag_before=$(
  curl -k -i -f -s -G \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| grep 'ETag' \
| tr -d '\r' \
| sed -En 's/^ETag: (.*)$/\1/p')

# append new triples to the graph

(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$END_USER_BASE_URL" <<EOF
<${END_USER_BASE_URL}named-subject-post> <http://example.com/default-predicate> "named object POST" .
<${END_USER_BASE_URL}named-subject-post> <http://example.com/another-predicate> "another named object POST" .
EOF
) \
| grep -q "$STATUS_NO_CONTENT"

# check that the ETag value changed

etag_after=$(
  curl -k -i -f -s -G \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| grep 'ETag' \
| tr -d '\r' \
| sed -En 's/^ETag: (.*)$/\1/p')

if [ "$etag_before" = "$etag_after" ]; then
    echo "The new ETag value '${etag_after}' is the same as the old one '${etag_before} despite the update'"
    exit 1
fi