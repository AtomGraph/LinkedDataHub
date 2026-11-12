#!/usr/bin/env bash
set -euo pipefail

# the counterpart of GET-timegate-after-write.sh: a dataspace without a versioning repository (the admin one, which no
# test stack versions) schedules no commits, so its TimeGate never waits - it answers 404 right after a write, as it
# always has

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')
doc_url="${ADMIN_BASE_URL}${slug}/"

echo "<${doc_url}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/document-hierarchy#Item> .
<${doc_url}> <http://purl.org/dc/terms/title> \"Unversioned\" ." | \
  ldh put \
    -c "$OWNER_CERT_KEYSTORE" \
    -p "$OWNER_CERT_PWD" \
    -t "application/n-triples" \
    "$doc_url"

headers=$(
curl -k -s -I \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  "${doc_url}?timegate" \
| tr -d '\r')

echo "$headers" | head -n 1 | grep -q ' 404'

if echo "$headers" | grep -qi '^Retry-After:'; then
    exit 1
fi
