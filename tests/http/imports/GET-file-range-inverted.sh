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

# a last position before the first cannot be satisfied: 416 with the complete length (RFC 9110 §15.5.17, §14.4)

status=$(curl -k -s -o /dev/null -D "$headers" -w "%{http_code}" \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/csv" \
  -H "Range: bytes=5-4" \
  "$file")
content_range=$(grep -i '^Content-Range:' "$headers" | tr -d '\r' | sed -E 's/^[^:]+: *//' || true)

echo "DEBUG: Expected status: $STATUS_RANGE_NOT_SATISFIABLE  Got: $status"
echo "DEBUG: Expected Content-Range: bytes */${length}  Got: '$content_range'"
[ "$status" = "$STATUS_RANGE_NOT_SATISFIABLE" ]
[ "$content_range" = "bytes */${length}" ]
