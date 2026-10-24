#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Whether a document exists is decided by its graph, so a PUT to a URI with no graph is a create, authorized
# against the parent container - even when another document already describes that URI, here as an
# nfo:FileDataObject, which the document type query types without a graph of its own.

container=$(ldh create container \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Drop box" \
  --slug "drop-box" \
  --parent "$END_USER_BASE_URL")

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Append to the drop box" \
  --agent "$AGENT_URI" \
  --to "$container" \
  --append \
  "$ADMIN_BASE_URL"

child="${container}$(uuidgen | tr '[:upper:]' '[:lower:]')/"

# the container's own graph describes the child's URI before the child exists

ldh patch \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  "$container" <<EOF
INSERT { <${child}> a <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#FileDataObject> ; <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#fileName> "described.txt" ; <http://purl.org/dc/terms/title> "Described" } WHERE {}
EOF

# a create-only PUT of the child is still a create in the container: 201

status=$(printf '<%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .\n<%s> <http://purl.org/dc/terms/title> "Dropped" .\n' "$child" "$child" \
  | curl -k -w "%{http_code}" -o /dev/null -s \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -X PUT \
    -H "Accept: application/n-triples" \
    -H "Content-Type: application/n-triples" \
    -H "If-None-Match: *" \
    --data-binary @- \
    "$child")
echo "DEBUG: create-only PUT of a child described in another graph. Expected: $STATUS_CREATED Got: $status"
[ "$status" = "$STATUS_CREATED" ] || exit 1
