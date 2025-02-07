#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the writers

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create container

slug="test"

graph=$(create-container.sh \
-f "$AGENT_CERT_FILE" \
-p "$AGENT_CERT_PWD" \
-b "$END_USER_BASE_URL" \
--title "Test" \
--slug "$slug" \
--parent "$END_USER_BASE_URL")

# import RDF from source URI

source="http://dig.csail.mit.edu/2008/webdav/timbl/foaf.rdf"

echo "Importing RDF from source: $source"

curl -w "%{http_code}\n" -o /dev/null -v -k \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/turtle" \
  -H "Content-Type: application/rdf+x-www-form-urlencoded" \
  --data-urlencode "rdf=" \
  --data-urlencode "sb=arg" \
  --data-urlencode "pu=http://purl.org/dc/terms/source" \
  --data-urlencode "ou=${source}" \
  --data-urlencode "pu=http://www.w3.org/ns/sparql-service-description#name" \
  --data-urlencode "ou=${graph}" \
  "${END_USER_BASE_URL}add" \
| grep -q "$STATUS_NO_CONTENT"

doc_ntriples=$(get.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "${END_USER_BASE_URL}service?graph=${graph}")

# check that the graph has been imported and contains the right triples

echo "$doc_ntriples" | grep "<http://dig.csail.mit.edu/2008/webdav/timbl/foaf.rdf> <http://xmlns.com/foaf/0.1/maker> <http://www.w3.org/People/Berners-Lee/card#i>"