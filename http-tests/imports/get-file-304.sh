#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

file=$(./create-file.sh)

pushd . > /dev/null && cd "$SCRIPT_ROOT"

etag=$(
./get-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept "text/csv" \
  "$file" \
| grep 'ETag' \
| sed -En 's/^ETag: (.*)/\1/p')

popd > /dev/null

curl -k -w "%{http_code}\n" -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: text/csv" \
  "$file" \
-H "If-None-Match: ${etag}" \
| grep -q "$STATUS_NOT_MODIFIED"