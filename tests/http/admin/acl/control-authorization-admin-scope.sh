#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# An authorization carrying acl:Control applies to what it targets, like any other: Control over one end-user
# document opens that document and nothing in the admin dataspace.

get_status() # document
{
  curl -k -w "%{http_code}" -o /dev/null -s \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -H "Accept: application/n-triples" \
    "$1"
}

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Controlled" \
  --slug "controlled" \
  --container "$END_USER_BASE_URL")

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Control of one document" \
  --agent "$AGENT_URI" \
  --to "$item" \
  --read \
  --write \
  --control \
  "$ADMIN_BASE_URL"

status=$(get_status "$item")
echo "DEBUG: the controlled document. Expected: $STATUS_OK Got: $status"
[ "$status" = "$STATUS_OK" ] || exit 1

for document in "$ADMIN_BASE_URL" "${ADMIN_BASE_URL}acl/groups/owners/" "${ADMIN_BASE_URL}acl/authorizations/full-control/"; do
    status=$(get_status "$document")
    echo "DEBUG: admin document <$document>. Expected: $STATUS_FORBIDDEN Got: $status"
    [ "$status" = "$STATUS_FORBIDDEN" ] || exit 1
done
