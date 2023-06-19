#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create public authorization

./create-authorization.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --label "Public access authorization" \
  --agent-class 'http://xmlns.com/foaf/0.1/Agent' \
  --to "$END_USER_BASE_URL" \
  --read

popd > /dev/null

# store the ETag value

pushd . > /dev/null && cd "$SCRIPT_ROOT"

etag_before=$(
  curl -k -i -f -s -G \
    -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| grep 'ETag' \
| tr -d '\r' \
| sed -En 's/^ETag: (.*)$/\1/p')

popd > /dev/null

# replace the graph

(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$END_USER_BASE_URL" <<EOF
<${END_USER_BASE_URL}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/default#Root> .
<${END_USER_BASE_URL}> <http://purl.org/dc/terms/title> "Root" .
<${END_USER_BASE_URL}named-subject-put> <http://example.com/default-predicate> "named object PUT" .
<${END_USER_BASE_URL}named-subject-put> <http://example.com/another-predicate> "another named object PUT" .
EOF
) \
| grep -q "$STATUS_OK"

# check that the ETag value changed

pushd . > /dev/null && cd "$SCRIPT_ROOT"

etag_after=$(
  curl -k -i -f -s -G \
    -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| grep 'ETag' \
| tr -d '\r' \
| sed -En 's/^ETag: (.*)$/\1/p')

popd > /dev/null

if [ "$etag_before" = "$etag_after" ]; then
    echo "The new ETag value '${etag_after}'is the same as the old one '${etag_before} despite the update'"
    exit 1
fi