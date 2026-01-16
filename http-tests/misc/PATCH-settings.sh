#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Test: PATCH /settings - Valid update (change title)

# Get initial ETag
initial_response=$(curl -i -k -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}settings")

etag=$(echo "$initial_response" | grep -i "ETag:" | sed 's/ETag: //i' | tr -d '\r\n')

# PATCH to update title
(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -X PATCH \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/sparql-update" \
  -d "PREFIX dct: <http://purl.org/dc/terms/>
DELETE { ?app dct:title ?title }
INSERT { ?app dct:title \"Updated Title\" }
WHERE { ?app dct:title ?title }" \
  "${END_USER_BASE_URL}settings"
) \
| grep -q "$STATUS_NO_CONTENT"

# Verify changes were persisted by GET
verify_response=$(curl -k -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}settings")

if ! echo "$verify_response" | grep -q "Updated Title"; then
  exit 1
fi

# Verify ETag changed after update
verify_etag_response=$(curl -i -k -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}settings")

new_etag=$(echo "$verify_etag_response" | grep -i "ETag:" | sed 's/ETag: //i' | tr -d '\r\n')

if [ "$etag" = "$new_etag" ]; then
  exit 1
fi

# Restore original title for subsequent tests
curl -k -w "%{http_code}\n" -o /dev/null -s -X PATCH \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Content-Type: application/sparql-update" \
  -d "PREFIX dct: <http://purl.org/dc/terms/>
DELETE { ?app dct:title ?title }
INSERT { ?app dct:title \"LinkedDataHub\" }
WHERE { ?app dct:title ?title }" \
  "${END_USER_BASE_URL}settings" > /dev/null
