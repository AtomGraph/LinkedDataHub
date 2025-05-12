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

# create new document - relative URIs allowed in Turtle and should resolve against the document URI as base

item="${END_USER_BASE_URL}new-item/"

(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: text/turtle" \
  --data-binary @- \
  "$item" <<EOF
<named-subject-put> <http://example.com/default-predicate> "named object PUT" .
<named-subject-put> <http://example.com/another-predicate> "another named object PUT" .
EOF
) \
| grep -q "$STATUS_CREATED"

# check that resource is accessible

curl -k -f -G -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item" \
| tr -d '\n' \
| grep "<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item>" \
| grep -q "<${item}named-subject-put> <http://example.com/default-predicate> \"named object PUT\" ."
