#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

slug="test"
container="${END_USER_BASE_URL}${slug}/"

# check that the access metadata does not contain writers group membership

ntriples=$(curl -k -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  --data "this=${container}" \
  "${ADMIN_BASE_URL}access"
)

if echo "$ntriples" | grep -q "<http://www.w3.org/ns/auth/acl#agentGroup> <${ADMIN_BASE_URL}acl/groups/writers/#this>"; then
  exit 1
fi

# add agent to the writers group

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create container

create-container.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test" \
  --slug "$slug" \
  --parent "$END_USER_BASE_URL"

# check that the access metadata does contain writers group membership

ntriples=$(curl -k -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  --data "this=${container}" \
  "${ADMIN_BASE_URL}access"
)

if ! echo "$ntriples" | grep -q "<http://www.w3.org/ns/auth/acl#agentGroup> <${ADMIN_BASE_URL}acl/groups/writers/#this>"; then
  exit 1
fi
