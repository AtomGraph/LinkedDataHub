#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# the TimeMap of a document is read-only: the 405 names the methods it allows, which do not include writes

headers=$(curl -k -o /dev/null -s -D - \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary "<${END_USER_BASE_URL}> <http://purl.org/dc/terms/title> \"Title\" ." \
  "${END_USER_BASE_URL}?timemap")

status=$(head -n 1 <<< "$headers" | cut -d ' ' -f 2)
allow=$(grep -i '^allow:' <<< "$headers" | tr -d '\r' || true)
echo "DEBUG: Expected status: $STATUS_METHOD_NOT_ALLOWED"
echo "DEBUG: Got status: $status"
echo "DEBUG: Got: $allow"
[ "$status" = "$STATUS_METHOD_NOT_ALLOWED" ]
grep -qw "GET" <<< "$allow"
for method in PUT POST PATCH DELETE; do
  if grep -qw "$method" <<< "$allow"; then echo "DEBUG: $method should not be allowed"; exit 1; fi
done
