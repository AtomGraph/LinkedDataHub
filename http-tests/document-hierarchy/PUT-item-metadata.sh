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

# replace the graph (note that the document does not have its description in the request body)

slug="test-item"
item="${END_USER_BASE_URL}${slug}/"

(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF
<${item}> <http://example.com/default-predicate> "named object PUT" .
EOF
) \
| grep -q "$STATUS_CREATED"

item_ntriples=$(get.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item"
 )

# check that the default RDF type was assigned to the new document

echo "$item_ntriples" | grep "<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item>"

# check that sioc:has_container was assigned to the new document

echo "$item_ntriples" | grep "<${item}> <http://rdfs.org/sioc/ns#has_container> <"

# check that dct:creator was assigned to the new document

echo "$item_ntriples" | grep "<${item}> <http://purl.org/dc/terms/creator> <"

# check that dct:created was assigned to the new document

echo "$item_ntriples" | grep "<${item}> <http://purl.org/dc/terms/created> \""

# write data again into the existing graph (with rdf:type added)

(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "$item" <<EOF
<${item}> <http://example.com/default-predicate> "named object PUT" .
<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${item}> <http://purl.org/dc/terms/title> "Title" .
EOF
) \
| grep -q "$STATUS_OK"

item_ntriples=$(get.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$item"
 )

# check that the default RDF type is still assigned to the document

echo "$item_ntriples" | grep "<${item}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item>"

# check that sioc:has_container is still assigned to the document

echo "$item_ntriples" | grep "<${item}> <http://rdfs.org/sioc/ns#has_container> <"

# check that dct:creator is still assigned to the document

echo "$item_ntriples" | grep "<${item}> <http://purl.org/dc/terms/creator> <"

# check that dct:created is still assigned to the document

echo "$item_ntriples" | grep "<${item}> <http://purl.org/dc/terms/created> \""

# check that dct:modified is assigned to the document

echo "$item_ntriples" | grep "<${item}> <http://purl.org/dc/terms/modified> \""

# check that exactly one dct:created and one dct:modified exist (no accumulation)

created_count=$(echo "$item_ntriples" | grep -c "<${item}> <http://purl.org/dc/terms/created> " || true)
if [ "$created_count" -ne 1 ]; then
    echo "Expected exactly 1 dct:created property after PUT, found $created_count"
    exit 1
fi

modified_count=$(echo "$item_ntriples" | grep -c "<${item}> <http://purl.org/dc/terms/modified> " || true)
if [ "$modified_count" -ne 1 ]; then
    echo "Expected exactly 1 dct:modified property after PUT, found $modified_count"
    exit 1
fi

# write the same data again into the existing graph