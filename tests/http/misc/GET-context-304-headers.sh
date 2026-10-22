#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# RFC 9110 15.4.5: a 304 carries the validators and Vary, not the representation's metadata. The HTML context's 304
# used to announce the selected variant's language (en-US) while its 200 announced the one the page is rendered in
# (en): a cache updating its stored headers from the 304 relabelled the page

headers=$(curl -k -s -D - -o /dev/null -H "Accept: text/html" -H "Accept-Language: en" "${END_USER_BASE_URL}context" | tr -d '\r')
status=$(echo "$headers" | head -n 1 | cut -d ' ' -f 2)
etag=$(echo "$headers" | grep -i '^etag:' | sed 's/^[Ee][Tt][Aa][Gg]: *//')
language=$(echo "$headers" | grep -i '^content-language:' | sed 's/^[^:]*: *//' || true)

echo "DEBUG: 200 status: $status  ETag: $etag  Content-Language: $language"
[ "$status" = "$STATUS_OK" ]
[ -n "$etag" ]

headers=$(curl -k -s -D - -o /dev/null -H "Accept: text/html" -H "Accept-Language: en" -H "If-None-Match: $etag" "${END_USER_BASE_URL}context" | tr -d '\r')
status=$(echo "$headers" | head -n 1 | cut -d ' ' -f 2)
not_modified_language=$(echo "$headers" | grep -i '^content-language:' | sed 's/^[^:]*: *//' || true)

echo "DEBUG: 304 status: $status  Content-Language: $not_modified_language"
echo "$headers"
[ "$status" = "$STATUS_NOT_MODIFIED" ]

# the application sends none; a 304 that a cache answers from its stored copy repeats that copy's own header, which
# at least agrees with the 200
if [ -n "$not_modified_language" ] && [ "$not_modified_language" != "$language" ]; then
  echo "DEBUG: the 304's Content-Language contradicts the 200's"
  exit 1
fi

echo "$headers" | grep -qi '^etag:'
