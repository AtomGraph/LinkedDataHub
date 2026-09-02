#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Federation browse leg: instance A's client dereferences instance B's document through A's
# Linked Data proxy. The wire carries a conneg GET; B's hypermedia (Link headers) is forwarded
# so the client discovers B's SPARQL endpoint and application at runtime, and B's ETag is
# forwarded so preconditioned writes against B validate. The two dataspaces share a triplestore
# below the HTTP surface (test config), but meet only through the full HTTP stack here.

remote_base="https://test.localhost:4443/"

headers=$(mktemp)
trap 'rm -f "$headers"' EXIT

# dereference B's root document through A's proxy

curl -k -f -s -o /dev/null -D "$headers" \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/rdf+xml" \
  --data-urlencode "uri=${remote_base}" \
  "$END_USER_BASE_URL"

# B's SPARQL endpoint is discovered from the forwarded Link header, not configured

grep -i '^link:' "$headers" | tr ',' '\n' | grep 'sparql-service-description#endpoint' | grep -q "${remote_base}sparql"

# B's application URI is forwarded too (it marks the remote as a Linked Data application)

grep -i '^link:' "$headers" | tr ',' '\n' | grep -q 'linkeddatahub/apps#application'

# the proxied response carries B's own ETag (resource-state validator), enabling If-Match writes

proxied_etag=$(grep -i '^etag:' "$headers" | tr -d '\r' | awk '{print $2}')
direct_etag=$(curl -k -f -s -I \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/rdf+xml" \
  "$remote_base" \
| grep -i '^etag:' | tr -d '\r' | awk '{print $2}')

if [ -z "$proxied_etag" ] || [ "$proxied_etag" != "$direct_etag" ]; then
  exit 1
fi
