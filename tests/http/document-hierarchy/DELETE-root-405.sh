#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# add agent to the owners

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/owners/"

# check that it's not possible to delete the root document

headers=$(curl -k -o /dev/null -s -D - \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X DELETE \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL")

# the 405 names the methods the resource allows

status=$(head -n 1 <<< "$headers" | cut -d ' ' -f 2)
allow=$(grep -i '^allow:' <<< "$headers" | tr -d '\r' || true)
echo "DEBUG: Expected status: $STATUS_METHOD_NOT_ALLOWED"
echo "DEBUG: Got status: $status"
echo "DEBUG: Got: $allow"
[ "$status" = "$STATUS_METHOD_NOT_ALLOWED" ]
grep -qw "GET" <<< "$allow"
grep -qw "PUT" <<< "$allow"
grep -qw "PATCH" <<< "$allow"
if grep -qw "DELETE" <<< "$allow"; then echo "DEBUG: DELETE should not be allowed"; exit 1; fi
