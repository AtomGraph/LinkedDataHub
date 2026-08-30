#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Federation write leg: A's client submits a graph-scoped SPARQL Update delta as a PATCH against
# B's document, through A's proxy, under an If-Match precondition using B's own ETag (forwarded
# by the proxy on the read). The proxy forwards the method, body and the agent's identity; B's
# ACL arbitrates. This is the read-write half of the federation test: browse, query, and write
# crossing the wire on spec-terms only.

remote_base="https://test.localhost:4443/"

# create the document on B (the owner is authorized on both dataspaces in the test setup)

item=$(ldh create-item \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$remote_base" \
  --title "Federation write target" \
  --slug "federation-patch-$(date +%s)" \
  --container "$remote_base")

# read the document through A's proxy, capturing B's ETag for the precondition

etag=$(curl -k -f -s -o /dev/null -D - \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/rdf+xml" \
  --data-urlencode "uri=${item}" \
  "$END_USER_BASE_URL" \
| grep -i '^etag:' | tr -d '\r' | awk '{print $2}')

echo "DEBUG: ETag for If-Match: $etag"
if [ -z "$etag" ]; then
  echo "DEBUG: no ETag on the proxied response"
  exit 1
fi

update=$(cat <<EOF
PREFIX dct: <http://purl.org/dc/terms/>

INSERT
{
  <${item}> dct:description "Updated across instances" .
}
WHERE {}
EOF
)

# a stale precondition is rejected by B - proves the proxy forwards If-Match and B evaluates it.
# Accept must match the read: LDH ETags are variant-specific (the negotiated media type folds into
# the tag), so the conditional PATCH negotiates the same rdf+xml variant the ETag above was read for.

stale_code=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -X PATCH \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Content-Type: application/sparql-update' \
  -H 'Accept: application/rdf+xml' \
  -H 'If-Match: "stale"' \
  --url-query "uri=${item}" \
  --data-binary "$update" \
  "$END_USER_BASE_URL")

echo "DEBUG: stale If-Match returned: $stale_code (expected $STATUS_PRECONDITION_FAILED)"
if [ "$stale_code" != "$STATUS_PRECONDITION_FAILED" ]; then
  exit 1
fi

# the delta with B's current ETag succeeds

valid_code=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -X PATCH \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Content-Type: application/sparql-update' \
  -H 'Accept: application/rdf+xml' \
  -H "If-Match: $etag" \
  --url-query "uri=${item}" \
  --data-binary "$update" \
  "$END_USER_BASE_URL")

echo "DEBUG: valid If-Match returned: $valid_code (expected $STATUS_NO_CONTENT)"
if [ "$valid_code" != "$STATUS_NO_CONTENT" ]; then
  exit 1
fi

# the delta landed on B - confirmed on B directly, not through the proxy

curl -k -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$item" \
| grep "Updated across instances" > /dev/null
