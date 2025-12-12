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

# create item document to PATCH

item=$(create-item.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test Item" \
  --slug "test-patch-$(date +%s)" \
  --container "$END_USER_BASE_URL")

# execute SPARQL UPDATE on the item using LDH as a proxy

update=$(cat <<EOF
PREFIX dcterms: <http://purl.org/dc/terms/>

INSERT
{
  <${item}> dcterms:description "Updated via proxy" .
}
WHERE {}
EOF
)

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -X PATCH \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Content-Type: application/sparql-update' \
  --url-query "uri=${item}" \
  --data-binary "$update" \
  "$END_USER_BASE_URL" \
| grep -q "$STATUS_NO_CONTENT"

# check that the data was inserted

curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  --url-query "uri=${item}" \
  "$END_USER_BASE_URL" \
| grep "Updated via proxy" > /dev/null
