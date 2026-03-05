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

filename="/tmp/random-file"
time dd if=/dev/urandom of="$filename" bs=1 count=1024
file_content_type="application/octet-stream"

# Create a container for files first
create-container.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Files" \
  --parent "$END_USER_BASE_URL" \
  --slug "files"

# Create an item document to hold the file
file_doc=$(create-item.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Random file" \
  --container "${END_USER_BASE_URL}files/")

# Add the file to the document
add-file.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Random file" \
  --file "$filename" \
  --content-type "${file_content_type}" \
  "$file_doc"

# Calculate file URI from SHA1 hash
sha1sum=$(shasum -a 1 "$filename" | awk '{print $1}')
file="${END_USER_BASE_URL}uploads/${sha1sum}"

server_sha1sum=$(echo "$file" | cut -d "/" -f 5) # cut the last URL path segment

file_sha1sum=$(sha1sum "$filename" | cut -d " " -f 1) # cut the following filename

if [ "$server_sha1sum" != "$file_sha1sum" ]; then
    echo "Server SHA1 hash '${server_sha1sum}' does not match the sha1sum '${file_sha1sum}'"
    exit 1
fi