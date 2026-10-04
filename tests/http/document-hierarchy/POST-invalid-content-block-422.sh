#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create an item with random slug

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')

item=$(ldh create item \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Test item" \
  --slug "$slug" \
  --container "$END_USER_BASE_URL")

# POST a block typed as something other than ldh:Object/ldh:XHTML into the item. The body does not type the
# item, so validated on its own ldh:InvalidContentBlockType has nothing to apply to; the document it is
# appended to is a dh:Item, and it is the whole document that gets written, so the POST is refused with 422
# and nothing is appended.

response=$(curl -k -w "%{http_code}\n" -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "If-Match: $(etag "$item" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")" \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF
<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#_2> <${item}#bad-block> .
<${item}#bad-block> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://spinrdf.org/sp#Construct> .
<${item}#bad-block> <http://purl.org/dc/terms/title> "Not a valid content block" .
<${item}#bad-block> <http://spinrdf.org/sp#text> "CONSTRUCT WHERE {}" .
EOF
)

status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

echo "DEBUG: Expected status: $STATUS_UNPROCESSABLE_ENTITY"
echo "DEBUG: Got status: $status"
if [ "$status" != "$STATUS_UNPROCESSABLE_ENTITY" ]; then
    echo "DEBUG: Status mismatch!"
    exit 1
fi

ntriples=$(echo "$body" | rapper -q --input ntriples --output ntriples /dev/stdin -)
echo "DEBUG: Response body as N-Triples:"
echo "$ntriples"

# the violation rooted in the document

expected="<http://spinrdf.org/spin#violationRoot> <${item}>"
echo "DEBUG: Expected present: $expected"
if ! echo "$ntriples" | grep -qF "$expected"; then
    echo "DEBUG: Violation root missing!"
    exit 1
fi

# nothing was appended

item_ntriples=$(curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item")

if grep -qF "<${item}#bad-block>" <<< "$item_ntriples"; then
    echo "DEBUG: The refused block was appended!"
    exit 1
fi
