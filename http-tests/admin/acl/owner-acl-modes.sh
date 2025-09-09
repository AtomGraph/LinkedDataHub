#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# test that the owner agent accessing BASE_URL returns correct Link header with all ACL modes

RESPONSE_HEADERS=$(mktemp)

curl -k -f \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -D "$RESPONSE_HEADERS" \
  -o /dev/null \
  "$END_USER_BASE_URL"

# check that each ACL mode is present in Link header (order independent)
grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Read>; rel=http://www.w3.org/ns/auth/acl#mode" "$RESPONSE_HEADERS"
grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Write>; rel=http://www.w3.org/ns/auth/acl#mode" "$RESPONSE_HEADERS"
grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Append>; rel=http://www.w3.org/ns/auth/acl#mode" "$RESPONSE_HEADERS"
grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Control>; rel=http://www.w3.org/ns/auth/acl#mode" "$RESPONSE_HEADERS"

rm "$RESPONSE_HEADERS"