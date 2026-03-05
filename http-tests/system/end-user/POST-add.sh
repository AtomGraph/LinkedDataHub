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

# create container to hold the cloned data

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')

container=$(create-container.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test container" \
  --slug "$slug" \
  --parent "$END_USER_BASE_URL")

# POST /add with a writer should succeed
# Clone data from a remote RDF source into the container

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "rdf=" \
  --data-urlencode "sb=clone" \
  --data-urlencode "pu=http://purl.org/dc/terms/source" \
  --data-urlencode "ou=https://orcid.org/0000-0003-1750-9906" \
  --data-urlencode "pu=http://www.w3.org/ns/sparql-service-description#name" \
  --data-urlencode "ou=${container}" \
  "${END_USER_BASE_URL}add" \
| grep -q "$STATUS_NO_CONTENT"
