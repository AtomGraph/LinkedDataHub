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

# A multipart PUT that says nothing about the document it creates gets the document typed dh:Item by the
# server, like a PUT with an RDF body, and is held to dh:Item's constraints the same way: def:MissingTitle
# refuses it with 422, and nothing is written.

item="${END_USER_BASE_URL}$(uuidgen | tr '[:upper:]' '[:lower:]')/"

status=$(curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -F "rdf=" \
  -F "su=${item}#thing" \
  -F "pu=http://www.w3.org/2000/01/rdf-schema#label" \
  -F "ol=Not the document" \
  "$item")

echo "DEBUG: Expected status: $STATUS_UNPROCESSABLE_ENTITY  Got: $status"
if [ "$status" != "$STATUS_UNPROCESSABLE_ENTITY" ]; then
    exit 1
fi

written=$(curl -s -G \
  -H "Accept: application/sparql-results+xml" \
  --data-urlencode "query=ASK { GRAPH <${item}> { ?s ?p ?o } }" \
  "$END_USER_ENDPOINT_URL" \
| xmllint --xpath "string(//*[local-name() = 'boolean'])" -)

echo "DEBUG: Expected graph written: false  Got: $written"
if [ "$written" != "false" ]; then
    echo "DEBUG: The refused document was written!"
    exit 1
fi
