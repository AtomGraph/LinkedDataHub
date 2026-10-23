#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A sign-up stores the agent's description and what the server adds to it: the agent's document is an admin graph,
# which the authorization queries read, so statements the payload makes about any other resource are not stored.
# Here the payload also states a group membership, which must neither be stored nor take effect.

uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
password="password-${uuid}"
keystore=$(mktemp)
cert=$(mktemp)
headers=$(mktemp)

curl -k -s -f -D "$headers" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "rdf=" \
  --data-urlencode "sb=agent" \
  --data-urlencode "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
  --data-urlencode "ou=http://xmlns.com/foaf/0.1/Person" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/primaryTopic" \
  --data-urlencode "ob=agent" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/based_near" \
  --data-urlencode "ou=http://www.wikidata.org/entity/Q35" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/mbox" \
  --data-urlencode "ol=${uuid}@example.com" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/familyName" \
  --data-urlencode "ol=Doe" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/givenName" \
  --data-urlencode "ol=Jane" \
  --data-urlencode "pu=http://www.w3.org/ns/auth/cert#key" \
  --data-urlencode "ob=key" \
  --data-urlencode "sb=key" \
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl#password" \
  --data-urlencode "ol=${password}" \
  --data-urlencode "pu=https://w3id.org/atomgraph/linkeddatahub/admin/acl#password" \
  --data-urlencode "ol=${password}" \
  --data-urlencode "su=${ADMIN_BASE_URL}acl/groups/owners/#this" \
  --data-urlencode "pu=http://xmlns.com/foaf/0.1/member" \
  --data-urlencode "ob=agent" \
  "${ADMIN_BASE_URL}sign%20up?download=true" \
> "$keystore"

agent_doc=$(grep -i '^location:' "$headers" | tr -d '\r' | cut -d' ' -f2)
echo "DEBUG: agent document: $agent_doc"
[ -n "$agent_doc" ] || exit 1

# every statement in the agent's document is about the document or a resource in it, but the secretary's delegation
# the server adds

agent_ntriples=$(ldh get \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$agent_doc")
foreign=$(echo "$agent_ntriples" | grep -vE "^<${agent_doc}(#[^>]*)?> " | grep -vE " <http://www.w3.org/ns/auth/acl#delegates> <${agent_doc}#[^>]*> \.$" || true)
echo "DEBUG: Expected statements about other resources: (none)"
echo "DEBUG: Got statements about other resources: $foreign"
[ -z "$foreign" ] || exit 1

# the membership the payload stated has no effect

openssl pkcs12 -in "$keystore" -out "$cert" -passin pass:"$password" -passout pass:"$password"

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$cert":"$password" \
  -H "Accept: application/n-triples" \
  "${ADMIN_BASE_URL}acl/groups/owners/")
echo "DEBUG: the owners group, as the new agent. Expected: $STATUS_FORBIDDEN Got: $status"
[ "$status" = "$STATUS_FORBIDDEN" ] || exit 1

rm -f "$keystore" "$cert" "$headers"
