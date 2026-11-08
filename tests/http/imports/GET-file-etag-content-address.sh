#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# An upload is described by every graph that mentions it, and any document can mention it (formal/uploads,
# any_writer_describes_any_upload). So its entity tag is the digest its URI is named by, whatever else a document
# states of it: a second foaf:sha1 used to make the tag a pick between the two (etag_content_addressed).

filename=$(mktemp)
trap 'rm -f "$filename"' EXIT
dd if=/dev/urandom of="$filename" bs=1 count=1024 2>/dev/null
sha1sum=$(shasum -a 1 "$filename" | awk '{print $1}')
file="${END_USER_BASE_URL}uploads/${sha1sum}"

file_doc=$(ldh create item \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "File" \
  --container "$END_USER_BASE_URL")

ldh add file \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "File" \
  --file "$filename" \
  --content-type "application/octet-stream" \
  "$file_doc"

# another document states a different digest of the same upload

other_doc=$(ldh create item \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Other" \
  --container "$END_USER_BASE_URL")

echo "INSERT DATA { <${file}> <http://xmlns.com/foaf/0.1/sha1> \"0000000000000000000000000000000000000000\" }" | \
  ldh patch \
    -c "$AGENT_CERT_KEYSTORE" \
    -p "$AGENT_CERT_PWD" \
    "$other_doc"

purge_cache "$END_USER_VARNISH_SERVICE"

etag=$(curl -k -f -s -o /dev/null -D - \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  "$file" | tr -d '\r' | sed -n 's/^[Ee][Tt]ag: *//p')

echo "DEBUG: Expected: \"${sha1sum}\""
echo "DEBUG: Got: ${etag}"
[ "$etag" = "\"${sha1sum}\"" ]

# and a request conditional on the stated digest is not answered as if it were the file's

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'If-None-Match: "0000000000000000000000000000000000000000"' \
  "$file")

echo "DEBUG: If-None-Match the stated digest: Expected: 200 Got: ${status}"
[ "$status" = "200" ]
