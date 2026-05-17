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

# create an item with random slug

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')

item=$(create-item.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test item" \
  --slug "$slug" \
  --container "$END_USER_BASE_URL")

# PUT a body where rdf:_1 points at an ldh:Object and rdf:_2 points at an ldh:XHTML.
# Both are the only types ldh:InvalidContentBlockType accepts. Expected: 200 OK.

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF \
| grep -q "$STATUS_OK"
<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${item}> <http://purl.org/dc/terms/title> "Test item" .
<${item}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}> .
<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#_1> <${item}#obj> .
<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#_2> <${item}#xhtml> .
<${item}#obj> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub#Object> .
<${item}#obj> <http://www.w3.org/1999/02/22-rdf-syntax-ns#value> <${END_USER_BASE_URL}> .
<${item}#xhtml> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub#XHTML> .
<${item}#xhtml> <http://www.w3.org/1999/02/22-rdf-syntax-ns#value> "<div xmlns=\"http://www.w3.org/1999/xhtml\"/>"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral> .
EOF
