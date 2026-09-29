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

# A multipart PUT to a document that does not exist yet creates it the way a PUT with an RDF body does: 201
# with a Location, and the type, container and creation metadata the server assigns. It used to write the
# form's triples as the graph and nothing else.

item="${END_USER_BASE_URL}$(uuidgen | tr '[:upper:]' '[:lower:]')/"

response=$(curl -k -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -D - \
  -o /dev/null \
  -F "rdf=" \
  -F "su=${item}" \
  -F "pu=http://purl.org/dc/terms/title" \
  -F "ol=Created through a form" \
  "$item")

http_code=$(echo "$response" | grep -m1 "^HTTP" | awk '{print $2}')
location=$(echo "$response" | grep -i "^location:" | tr -d '\r' | awk '{print $2}')

echo "DEBUG: Expected status: $STATUS_CREATED  Got: $http_code"
echo "DEBUG: Expected Location: $item  Got: $location"
[ "$http_code" = "$STATUS_CREATED" ]
[ "$location" = "$item" ]

item_ntriples=$(curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item")
echo "DEBUG: Created document:"
echo "$item_ntriples"

for triple in \
  "<${item}> <http://purl.org/dc/terms/title> \"Created through a form\"" \
  "<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item>" \
  "<${item}> <http://rdfs.org/sioc/ns#has_container> <${END_USER_BASE_URL}>" \
  "<${item}> <http://purl.org/dc/terms/created> \"" \
  "<${item}> <http://purl.org/dc/terms/creator> <" \
  "<${item}> <http://www.w3.org/ns/auth/acl#owner> <"
do
  if ! grep -qF "$triple" <<< "$item_ntriples"; then
    echo "DEBUG: Missing: $triple"
    exit 1
  fi
done
