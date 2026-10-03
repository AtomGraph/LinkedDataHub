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

# An upload is a multipart POST appended to the document, without If-Match. It is held to the constraints of
# the document it lands in as a whole, before any file is written: one that also appends a block typed as
# something other than ldh:Object/ldh:XHTML to the dh:Item is refused with 422, and its file is not stored.

test_file=$(mktemp)
echo "file refused with its document $(uuidgen)" > "$test_file" # content no other test uploads
sha1sum=$(shasum -a 1 "$test_file" | awk '{print $1}')

status=$(curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Accept: application/n-triples" \
  -F "rdf=" \
  -F "sb=file" \
  -F "pu=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#fileName" \
  -F "ol=@${test_file};type=text/plain" \
  -F "pu=http://purl.org/dc/terms/title" \
  -F "ol=Refused file" \
  -F "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
  -F "ou=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#FileDataObject" \
  -F "su=${item}" \
  -F "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#_2" \
  -F "ou=${item}#bad-block" \
  -F "su=${item}#bad-block" \
  -F "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
  -F "ou=http://spinrdf.org/sp#Construct" \
  "$item")

rm -f "$test_file"

echo "DEBUG: Expected status: $STATUS_UNPROCESSABLE_ENTITY  Got: $status"
if [ "$status" != "$STATUS_UNPROCESSABLE_ENTITY" ]; then
    exit 1
fi

# neither the block nor the file's description was appended

item_ntriples=$(curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item")

if grep -qF "#bad-block>" <<< "$item_ntriples" || grep -qF "\"Refused file\"" <<< "$item_ntriples"; then
    echo "DEBUG: The refused upload was appended!"
    exit 1
fi

# and the file was not stored

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  "${END_USER_BASE_URL}uploads/${sha1sum}")

echo "DEBUG: Refused file status: $status"
if [ "$status" = "$STATUS_OK" ]; then
    echo "DEBUG: The refused file was stored!"
    exit 1
fi
