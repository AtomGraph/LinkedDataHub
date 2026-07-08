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

# PATCH the root with an INSERT that introduces a blank node.
# Use rdf:_99 to avoid colliding with existing rdf:_1..rdf:_8 in the test dataset.
# Expected: 204 No Content; the blank node is skolemized to a hash URI before persisting.

update=$(cat <<EOF
PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX  dct:  <http://purl.org/dc/terms/>

INSERT
{
  <${END_USER_BASE_URL}> rdf:_99 _:bnode0 .
  _:bnode0 dct:title "Blank node title"
}
WHERE
{}
EOF
)

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Content-Type: application/sparql-update" \
  "$END_USER_BASE_URL" \
   --data-binary "$update" \
| grep -q "$STATUS_NO_CONTENT"

# fetch the persisted graph and verify the blank node was skolemized to a hash URI

response=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL")

rdf_99_line=$(echo "$response" | grep -E "^<${END_USER_BASE_URL}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#_99>" || true)

[ -n "$rdf_99_line" ] || exit 1

# object of rdf:_99 must be a URI (<...>), not a blank node label (_:...)
! echo "$rdf_99_line" | grep -qE '_:[A-Za-z0-9]+ \.$'
echo "$rdf_99_line" | grep -qE '<\S+> \.$'
