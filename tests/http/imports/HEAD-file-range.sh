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

# Range is defined for GET only (RFC 9110 §14.2): HEAD answers as the 200 of a GET without Range, with the
# full length

status=$(curl -k -s --head -o /dev/null -D "$headers" -w "%{http_code}" \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/csv" \
  -H "Range: bytes=0-9" \
  "$file")
content_range=$(grep -i '^Content-Range:' "$headers" | tr -d '\r' | sed -E 's/^[^:]+: *//' || true)
content_length=$(grep -i '^Content-Length:' "$headers" | tr -d '\r' | sed -E 's/^[^:]+: *//' || true)

echo "DEBUG: Expected status: $STATUS_OK  Got: $status"
echo "DEBUG: Expected no Content-Range  Got: '$content_range'"
echo "DEBUG: Expected Content-Length: $length  Got: '$content_length'"
[ "$status" = "$STATUS_OK" ]
[ -z "$content_range" ]
[ "$content_length" = "$length" ]
