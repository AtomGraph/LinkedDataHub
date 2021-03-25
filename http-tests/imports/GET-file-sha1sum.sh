#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pwd=$(realpath -s "$PWD")

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group to be able to read/write documents (might already be done by another test)

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

pushd . > /dev/null && cd "$SCRIPT_ROOT/imports"

# create file

filename="/tmp/random-file"
time dd if=/dev/urandom of="$filename" bs=1 count=1024
file_content_type="application/octet-stream"

file_doc=$(./create-file.sh \
-f "$AGENT_CERT_FILE" \
-p "$AGENT_CERT_PWD" \
-b "$END_USER_BASE_URL" \
--title "Test CSV" \
--file "$filename" \
--file-content-type "${file_content_type}")

pushd . > /dev/null && cd "$SCRIPT_ROOT"

file_ntriples=$(./get-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$file_doc")

popd > /dev/null

file=$(echo "$file_ntriples" \
| grep '<http://xmlns.com/foaf/0.1/primaryTopic>' \
| cut -d " " -f 3 \
| cut -d "<" -f 2 \
| cut -d ">" -f 1) # cut < > to get URI

server_sha1sum=$(echo "$file" | cut -d "/" -f 5) # cut the last URL path segment

file_sha1sum=$(sha1sum "$filename" | cut -d " " -f 1) # cut the following filename

if [ "$server_sha1sum" != "$file_sha1sum" ]; then
    echo "Server SHA1 hash '${server_sha1sum}' does not match the sha1sum '${file_sha1sum}'"
    exit 1
fi

popd > /dev/null