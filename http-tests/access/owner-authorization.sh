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

# create container

slug="test"

container=$(create-container.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test" \
  --slug "$slug" \
  --parent "$END_USER_BASE_URL")

# check that the access metadata for the container URI inclused owner authorization for the agent

ntriples=$(curl -k -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  --data "this=${container}" \
  "${END_USER_BASE_URL}access"
)

auth1=$(echo "$ntriples" | grep -F "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/admin/acl#OwnerAuthorization>" | cut -d' ' -f1)
auth2=$(echo "$ntriples" | grep -F "<http://www.w3.org/ns/auth/acl#agent> <${AGENT_URI}>" | cut -d' ' -f1)

# if the subjects of the two triples are different, the agent is not the owner of the container
if [ "$auth1" != "$auth2" ]; then
  exit 1
fi
