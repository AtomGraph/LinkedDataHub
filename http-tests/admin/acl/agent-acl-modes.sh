#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# test that the signed up agent accessing BASE_URL returns correct Link header with ACL modes (no Control)

RESPONSE_HEADERS=$(mktemp)

curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -D "$RESPONSE_HEADERS" \
  -o /dev/null \
  "$END_USER_BASE_URL"

cat "$RESPONSE_HEADERS"

# check that each expected ACL mode is present in Link header (order independent)
# signed up agents should have Read, Write, Append but NOT Control
grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Read>; rel=http://www.w3.org/ns/auth/acl#mode" "$RESPONSE_HEADERS"
grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Write>; rel=http://www.w3.org/ns/auth/acl#mode" "$RESPONSE_HEADERS"
grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Append>; rel=http://www.w3.org/ns/auth/acl#mode" "$RESPONSE_HEADERS"

# verify Control mode is NOT present for signed up agent
! grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Control>; rel=http://www.w3.org/ns/auth/acl#mode" "$RESPONSE_HEADERS"

rm "$RESPONSE_HEADERS"