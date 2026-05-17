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

# PUT a body where rdf:_1 points at a block typed as something other than ldh:Object/ldh:XHTML
# (here: sp:Construct, a SPARQL query — must be wrapped in ldh:Object to be a valid block).
# Expected: rejected by ldh:InvalidContentBlockType with 422.

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF \
| grep -q "$STATUS_UNPROCESSABLE_ENTITY"
<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${item}> <http://purl.org/dc/terms/title> "Test item" .
<${item}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}> .
<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#_1> <${item}#bad-block> .
<${item}#bad-block> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://spinrdf.org/sp#Construct> .
<${item}#bad-block> <http://purl.org/dc/terms/title> "Not a valid content block" .
<${item}#bad-block> <http://spinrdf.org/sp#text> "CONSTRUCT WHERE {}" .
EOF
