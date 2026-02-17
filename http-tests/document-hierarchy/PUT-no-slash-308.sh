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

# create test container

container=$(create-container.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test Container" \
  --slug "test-container" \
  --parent "$END_USER_BASE_URL")

# add an explicit read/write authorization for the parent since the child document will inherit it

create-authorization.sh \
  -b "$ADMIN_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --label "Write base" \
  --agent "$AGENT_URI" \
  --to "$container" \
  --read \
  --write

# check URI without trailing slash gets redirected

invalid_item="${container}no-slash"

(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$invalid_item" <<EOF
<${invalid_item}> <http://example.com/default-predicate> "named object PUT" .
EOF
) \
| grep -q "$STATUS_PERMANENT_REDIRECT"

# check that document gets created using a URI with a trailing slash if the redirect is followed (curl -L)

(
curl -k -L -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$invalid_item" <<EOF
<${invalid_item}> <http://example.com/default-predicate> "named object PUT" .
EOF
) \
| grep -q "$STATUS_CREATED"

item="${invalid_item}/" # URI with trailing slash

curl -k  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item" \
| tr -d '\n' \
| grep '"named object PUT"' \
| grep "<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item>"
