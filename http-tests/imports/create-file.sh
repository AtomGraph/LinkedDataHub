#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

pwd=$(realpath "$PWD")

# add agent to the writers group

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create file

file_content_type="text/csv"
slug=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Create an item document to hold the file
file_doc=$(create-item.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test CSV" \
  --container "$END_USER_BASE_URL" \
  --slug "$slug")

# Add the file to the document
add-file.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test CSV" \
  --file "$pwd/test.csv" \
  --content-type "${file_content_type}" \
  "$file_doc"

# Calculate file URI from SHA1 hash
sha1sum=$(shasum -a 1 "$pwd/test.csv" | awk '{print $1}')
file="${END_USER_BASE_URL}uploads/${sha1sum}"

echo "$file" # file URL used in other tests

curl --head -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: ${file_content_type}" \
  "$file" \
| grep -q "$STATUS_OK"