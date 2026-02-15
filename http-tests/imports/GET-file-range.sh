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
slug=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Create an item document to hold the file
file_doc=$(create-item.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Random file" \
  --container "$END_USER_BASE_URL" \
  --slug "$slug")

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

from=100
length=42
to=$(($length + $from - 1))

range1="$(mktemp)" || exit 1
range2="$(mktemp)" || exit 1

curl -k \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  --range "$from"-"$to" \
  "$file" \
  > "$range1"

# extract byte range

dd skip="$from" count="$length" if="$filename" of="$range2" bs=1

# compare byte ranges

cmp -s "$range1" "$range2"