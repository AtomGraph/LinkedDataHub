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

# create container

slug="test"

container=$(ldh create container \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Test" \
  --slug "$slug" \
  --parent "$END_USER_BASE_URL")

# check that the access metadata for the container URI includes the owner access authorization, granted to
# lacl:OwnerAgent, which the agent is a member of on the container it created

ntriples=$(curl -k -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  --data "this=${container}" \
  "${END_USER_BASE_URL}access"
)

owner_auth=$(echo "$ntriples" | grep -F "<http://www.w3.org/ns/auth/acl#agentClass> <https://w3id.org/atomgraph/linkeddatahub/admin/acl#OwnerAgent>" | cut -d' ' -f1 || true)
echo "DEBUG: owner access authorization: $owner_auth"
[ -n "$owner_auth" ] || exit 1

# it carries acl:Write
echo "$ntriples" | grep -qF "${owner_auth} <http://www.w3.org/ns/auth/acl#mode> <http://www.w3.org/ns/auth/acl#Write>" 
