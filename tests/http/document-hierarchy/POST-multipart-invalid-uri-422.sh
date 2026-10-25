#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A multipart RDF/POST, as an upload form sends, with a malformed object URI is refused with 422 naming the value, as
# an RDF body is. Nothing is appended.

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Target" \
  --slug "post-multipart-invalid-uri" \
  --container "$END_USER_BASE_URL")

response=$(curl -k -w "%{http_code}\n" -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Accept: application/n-triples" \
  -F "rdf=" \
  -F "su=${item}#this" \
  -F "pu=http://www.w3.org/2000/01/rdf-schema#seeAlso" \
  -F "ou=not a uri" \
  "$item")

status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

echo "DEBUG: Expected status: $STATUS_UNPROCESSABLE_ENTITY"
echo "DEBUG: Got status: $status"
echo "DEBUG: Body:"
echo "$body"
if [ "$status" != "$STATUS_UNPROCESSABLE_ENTITY" ]; then
    echo "DEBUG: Status mismatch!"
    exit 1
fi

expected="<https://w3id.org/atomgraph/linkeddatahub#violationValue> \"not a uri\""
echo "DEBUG: Expected present: $expected"
if ! grep -qF "$expected" <<< "$body"; then
    echo "DEBUG: Violation value missing!"
    exit 1
fi

item_ntriples=$(curl -k -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item")

if grep -qF "<http://www.w3.org/2000/01/rdf-schema#seeAlso>" <<< "$item_ntriples"; then
    echo "DEBUG: The refused upload was appended!"
    echo "$item_ntriples"
    exit 1
fi
