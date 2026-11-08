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

# An upload is served with the media type it was first uploaded with, which the platform records beside the bytes
# (formal/uploads, format_first_uploaders). Any document can state a dct:format of the file, and the description is
# merged from all of them, so a second one used to make the served type a pick between the two.

filename=$(mktemp)
trap 'rm -f "$filename"' EXIT
dd if=/dev/urandom of="$filename" bs=1 count=512 2>/dev/null
file="${END_USER_BASE_URL}uploads/$(shasum -a 1 "$filename" | awk '{print $1}')"

file_doc=$(ldh create item \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Image" \
  --container "$END_USER_BASE_URL")

ldh add file \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Image" \
  --file "$filename" \
  --content-type "image/png" \
  "$file_doc"

# another document states other formats of the same upload

other_doc=$(ldh create item \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Other" \
  --container "$END_USER_BASE_URL")

echo "INSERT DATA { <${file}> <http://purl.org/dc/terms/format> <http://www.sparontologies.net/mediatype/text/html>, <http://www.sparontologies.net/mediatype/application/octet-stream> }" | \
  ldh patch \
    -c "$AGENT_CERT_KEYSTORE" \
    -p "$AGENT_CERT_PWD" \
    "$other_doc"

content_type=$(curl -k -f -s -o /dev/null -w "%{content_type}" \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  "$file")

echo "DEBUG: Expected: image/png Got: ${content_type}"
[ "$content_type" = "image/png" ]
