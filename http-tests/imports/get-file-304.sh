#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

file_url=$(./create-file.sh)

pushd . > /dev/null && cd "$SCRIPT_ROOT"

etag=$(
./get-document.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --accept "text/csv" \
  "${file_url}" \
| grep 'ETag' \
| sed -En 's/^ETag: (.*)/\1/p')

curl -k -w "%{http_code}\n" -f -v -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: text/csv" \
  "${file_url}" \
-H "If-None-Match: $etag" \
| grep -q "${STATUS_NOT_MODIFIED}"

popd