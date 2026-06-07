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

# create a container under root; it becomes the PUT target

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')

container=$(create-container.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test container" \
  --slug "$slug" \
  --parent "$END_USER_BASE_URL")

# PUT a body where rdf:_1 references a bnode that has NO further triples
# (an orphan blank node in object position). The body is otherwise valid
# (title is present, parent is present), so SPIN constraints pass.
# Expected: 200 OK.

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$container" <<EOF \
| grep -q "$STATUS_OK"
<${container}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Container> .
<${container}> <http://purl.org/dc/terms/title> "Test container" .
<${container}> <http://rdfs.org/sioc/ns#has_parent> <${END_USER_BASE_URL}> .
<${container}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#_1> _:orphan .
EOF

# fetch the persisted representation and assert: the object of rdf:_1 is a URI,
# never a blank node label. The Skolemizer must have rewritten _:orphan to a
# skolem URI before the graph reached the store.

response=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$container")

rdf_1_line=$(echo "$response" | grep -E "^<${container}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#_1>" || true)

[ -n "$rdf_1_line" ] || exit 1

# object of rdf:_1 must be a URI (<...>), not a blank node label (_:...)
! echo "$rdf_1_line" | grep -qE '_:[A-Za-z0-9]+ \.$'
echo "$rdf_1_line" | grep -qE '<\S+> \.$'
