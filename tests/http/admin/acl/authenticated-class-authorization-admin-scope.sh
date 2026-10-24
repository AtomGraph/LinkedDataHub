#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# `ldh admin make-public` extends the public authorization - foaf:Agent and acl:AuthenticatedAgent - with acl:Read on
# the end-user root and, through acl:default, on every document below it. The admin dataspace is another tree, so a
# signed-in agent reads no more of it than an anonymous one: the documents authorizations name for everyone.

get_status() # document
{
  curl -k -w "%{http_code}" -o /dev/null -s \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -H "Accept: application/n-triples" \
    "$1"
}

ldh admin make-public \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  "$END_USER_BASE_URL"

status=$(get_status "$END_USER_BASE_URL")
echo "DEBUG: the end-user root, signed in. Expected: $STATUS_OK Got: $status"
[ "$status" = "$STATUS_OK" ] || exit 1

for document in "${ADMIN_BASE_URL}acl/groups/owners/" "${ADMIN_BASE_URL}acl/authorizations/full-control/" "${ADMIN_BASE_URL}acl/users/"; do
    status=$(get_status "$document")
    echo "DEBUG: admin document <$document>, signed in. Expected: $STATUS_FORBIDDEN Got: $status"
    [ "$status" = "$STATUS_FORBIDDEN" ] || exit 1
done

# the admin documents public to everyone stay public to a signed-in agent too

status=$(curl -k -w "%{http_code}" -o /dev/null -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/sparql-results+json" \
  --data-urlencode "query=ASK {}" \
  "${ADMIN_BASE_URL}ns")
echo "DEBUG: the admin namespace, signed in. Expected: $STATUS_OK Got: $status"
[ "$status" = "$STATUS_OK" ] || exit 1
