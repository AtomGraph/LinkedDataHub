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

created=$(curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item" \
| grep "^<${item}> <http://purl.org/dc/terms/created> ")

# A multipart PUT - the document form's, whose files have to be written before the RDF - is the same PUT as
# one with an RDF body: it wrote the form's triples as the graph and nothing else, so a document saved
# through the form lost its created/creator/owner metadata and container, and its If-Match was never checked.
# The body here says only what the form would: the document's new title.

function put_multipart()
{
  curl -k -w "%{http_code}\n" -o /dev/null -s \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -X PUT \
    -H "Accept: application/n-triples" \
    "$@" \
    -F "rdf=" \
    -F "su=${item}" \
    -F "pu=http://purl.org/dc/terms/title" \
    -F "ol=Renamed item" \
    "$item"
}

# without If-Match: the document exists, so the write has to say which state it was made against

status=$(put_multipart)
echo "DEBUG: [no If-Match] Expected status: $STATUS_PRECONDITION_REQUIRED  Got: $status"
if [ "$status" != "$STATUS_PRECONDITION_REQUIRED" ]; then
    exit 1
fi

# with If-Match: the write lands

status=$(put_multipart -H "If-Match: $(etag "$item" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")")
echo "DEBUG: [If-Match] Expected status: $STATUS_OK  Got: $status"
if [ "$status" != "$STATUS_OK" ]; then
    exit 1
fi

item_ntriples=$(curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item")
echo "DEBUG: Document after the multipart PUT:"
echo "$item_ntriples"

# the new title, and the metadata the server keeps or assigns

for triple in \
  "<${item}> <http://purl.org/dc/terms/title> \"Renamed item\"" \
  "$created" \
  "<${item}> <http://purl.org/dc/terms/creator> <" \
  "<${item}> <http://www.w3.org/ns/auth/acl#owner> <" \
  "<${item}> <http://purl.org/dc/terms/modified> \"" \
  "<${item}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}>" \
  "<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item>"
do
  if ! grep -qF "$triple" <<< "$item_ntriples"; then
    echo "DEBUG: Missing: $triple"
    exit 1
  fi
done
