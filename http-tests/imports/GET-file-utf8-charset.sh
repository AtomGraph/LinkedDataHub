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

# create text file with UTF-8 characters

filename="/tmp/utf8-test.md"
cat > "$filename" <<'EOF'
# UTF-8 Test File

This file contains UTF-8 characters:
- Em dash: —
- Arrow: →
- Emoji: 🚀
- Accented: café, naïve
EOF

file_content_type="text/markdown"

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
  --title "UTF-8 test file" \
  --container "${END_USER_BASE_URL}files/")

# Add the file to the document
add-file.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "UTF-8 test file" \
  --file "$filename" \
  --content-type "${file_content_type}" \
  "$file_doc"

# Calculate file URI from SHA1 hash
sha1sum=$(shasum -a 1 "$filename" | awk '{print $1}')
file="${END_USER_BASE_URL}uploads/${sha1sum}"

# Get Content-Type header from the file
content_type=$(
  curl -k -i -f -s -G \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  "$file" \
| grep -i 'Content-Type' \
| tr -d '\r' \
| sed -En 's/^[Cc]ontent-[Tt]ype: (.*)$/\1/p')

# Verify Content-Type contains charset=UTF-8
if ! echo "$content_type" | grep -q "charset=UTF-8"; then
    exit 1
fi

# Get the file content
file_content=$(
  curl -k -f -s -G \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  "$file")

# Verify UTF-8 characters are preserved
if ! echo "$file_content" | grep -q "—"; then
    exit 1
fi

if ! echo "$file_content" | grep -q "→"; then
    exit 1
fi

if ! echo "$file_content" | grep -q "🚀"; then
    exit 1
fi
