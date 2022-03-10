#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add an explicit read/write authorization for the owner because add-agent-to-group.sh won't work non-existing URI

./create-authorization.sh \
  -b "$ADMIN_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --label "Write base" \
  --agent "$AGENT_URI" \
  --to "$END_USER_BASE_URL" \
  --read \
  --write

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
<${END_USER_BASE_URL}named-subject-put> <http://example.com/default-predicate> "named object PUT" .
<${END_USER_BASE_URL}named-subject-put> <http://example.com/another-predicate> "another named object PUT" .
EOF
) \
| grep -q "$STATUS_OK"

# check that resource is accessible

curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| tr -d '\n' \
| grep '"named object PUT"' \
| grep -v '"named object"' > /dev/null