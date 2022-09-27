#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pwd=$(realpath -s "$PWD")

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group

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
--title "Random file" \
--file "$filename" \
--file-content-type "${file_content_type}")

popd > /dev/null

pushd . > /dev/null && cd "$SCRIPT_ROOT"

file_doc_ntriples=$(./get-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$file_doc")

popd > /dev/null

file=$(echo "$file_doc_ntriples" | sed -rn "s/<${file_doc//\//\\/}> <http:\/\/xmlns.com\/foaf\/0.1\/primaryTopic> <(.*)> \./\1/p")

from=10
length=5
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

cmp "$range1" "$range2"