#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# create a new document to test ACL modes against

doc_url=$(create-item.sh \
  -b "$END_USER_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --container "$END_USER_BASE_URL" \
  --title "ACL Test Document" \
  --slug "acl-test-document"
)

# test that the owner agent accessing the document returns correct Link header with all ACL modes

response_headers=$(mktemp)

curl -k -f -v \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -D "$response_headers" \
  -o /dev/null \
  "$doc_url"

cat "$response_headers"

# check that each ACL mode is present in Link header (order independent)
grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Read>; rel=http://www.w3.org/ns/auth/acl#mode" "$response_headers"
grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Write>; rel=http://www.w3.org/ns/auth/acl#mode" "$response_headers"
grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Append>; rel=http://www.w3.org/ns/auth/acl#mode" "$response_headers"
grep -q "Link:.*<http://www.w3.org/ns/auth/acl#Control>; rel=http://www.w3.org/ns/auth/acl#mode" "$response_headers"

rm "$response_headers"