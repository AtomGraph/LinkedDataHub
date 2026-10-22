#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

pwd=$(realpath "$PWD")

# upload test.csv and capture the file URI create-file.sh outputs

file=$(./create-file.sh)
length=$(wc -c < "$pwd/test.csv" | tr -d ' ')

headers="$(mktemp)" || exit 1
body="$(mktemp)" || exit 1
expected="$(mktemp)" || exit 1

# read the validators

curl -k -s -f -o /dev/null -D "$headers" \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/csv" \
  "$file"
etag=$(grep -i '^ETag:' "$headers" | tr -d '\r' | sed -E 's/^[^:]+: *//')
last_modified=$(grep -i '^Last-Modified:' "$headers" | tr -d '\r' | sed -E 's/^[^:]+: *//')
echo "DEBUG: ETag: $etag  Last-Modified: $last_modified"

head -c 10 "$pwd/test.csv" > "$expected"

# RFC 9110 §13.1.5: a matching If-Range validator - the entity tag, or the Last-Modified date - serves the range

for validator in "$etag" "$last_modified"; do
  status=$(curl -k -s -o "$body" -D "$headers" -w "%{http_code}" \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -H "Accept: text/csv" \
    -H "Range: bytes=0-9" \
    -H "If-Range: ${validator}" \
    "$file")
  content_range=$(grep -i '^Content-Range:' "$headers" | tr -d '\r' | sed -E 's/^[^:]+: *//' || true)

  echo "DEBUG: If-Range: $validator"
  echo "DEBUG: Expected status: $STATUS_PARTIAL_CONTENT  Got: $status"
  echo "DEBUG: Expected Content-Range: bytes 0-9/${length}  Got: '$content_range'"
  [ "$status" = "$STATUS_PARTIAL_CONTENT" ]
  [ "$content_range" = "bytes 0-9/${length}" ]

  cmp "$body" "$expected"
done
