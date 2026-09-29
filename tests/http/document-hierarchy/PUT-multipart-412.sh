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
  -b "$END_USER_BASE_URL" \
  --title "Test item" \
  --slug "$slug" \
  --container "$END_USER_BASE_URL")

# A multipart PUT - the document form's - answers to If-Match like any other write: one made against a state
# of the document that has since changed is refused, and the change made in between survives.

stale_etag=$(etag "$item" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")

# someone else's change, made after that state was read

curl -k -f -s -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "If-Match: $stale_etag" \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/sparql-update" \
  --data-binary "INSERT { <${item}> <http://purl.org/dc/terms/description> \"Changed in between\" } WHERE { }" \
  "$item"

status=$(curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "If-Match: $stale_etag" \
  -F "rdf=" \
  -F "su=${item}" \
  -F "pu=http://purl.org/dc/terms/title" \
  -F "ol=Overwriting title" \
  "$item")

echo "DEBUG: Expected status: $STATUS_PRECONDITION_FAILED  Got: $status"
if [ "$status" != "$STATUS_PRECONDITION_FAILED" ]; then
    exit 1
fi

item_ntriples=$(curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item")

if ! grep -qF "<${item}> <http://purl.org/dc/terms/description> \"Changed in between\"" <<< "$item_ntriples"; then
    echo "DEBUG: The change made in between was overwritten!"
    exit 1
fi
if grep -qF "\"Overwriting title\"" <<< "$item_ntriples"; then
    echo "DEBUG: The refused write landed!"
    exit 1
fi
