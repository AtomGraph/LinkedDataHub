#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Exercises the client-orchestrated "Add data" flow that replaced the server-side /add endpoint:
# the browser GETs the external source through the same-origin ?uri= proxy as RDF/XML, then
# POSTs (appends) it to the target document. Two requests, no /add endpoint.

# add agent to the readers group (to read through the proxy) and the writers group (to append)

ldh admin acl add-agent-to-group \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/readers/"

ldh admin acl add-agent-to-group \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create the target container

container=$(ldh create-container \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test" \
  --slug "test" \
  --parent "$END_USER_BASE_URL")

# step 1: fetch the external source through the LDH proxy, converted to RDF/XML

source_rdfxml=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/rdf+xml" \
  --data-urlencode "uri=https://orcid.org/0000-0003-1750-9906" \
  "$END_USER_BASE_URL")

# step 2: append the fetched triples to the target container document (GSP append -> 204)

echo "$source_rdfxml" | curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/rdf+xml" \
  --data-binary @- \
  "$container" \
| grep -q "$STATUS_NO_CONTENT"
