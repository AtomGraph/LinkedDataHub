#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

pwd=$(realpath -s "$PWD")

pushd . > /dev/null && cd "$SCRIPT_ROOT/imports"

# create file

file_content_type="text/csv"

file_url=$(./create-file.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$END_USER_BASE_URL" \
--title "Test CSV" \
--file "$pwd/test.csv" \
--file-content-type "${file_content_type}")

echo "${file_url}"

popd > /dev/null

curl --head -k -w "%{http_code}\n" -f -s \
  -E "${OWNER_CERT_FILE}":"${OWNER_CERT_PWD}" \
  -H "Accept: ${file_content_type}" \
  "${file_url}" \
| grep -q "${STATUS_OK}"