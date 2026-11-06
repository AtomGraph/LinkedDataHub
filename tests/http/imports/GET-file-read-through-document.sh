#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# An upload is readable by whoever may read a document it was uploaded into (formal/uploads, upload_readable). It has
# no graph of its own, so a grant on one document used not to reach the files uploaded into it; and since any
# document can describe a file, it is the platform's record of where the bytes were uploaded that counts, not a
# statement of the file in some graph. The agent is in no group: all it has is the grant below.

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

upload()
{
    local doc="$1" file="$2"
    dd if=/dev/urandom of="$file" bs=1 count=512 2>/dev/null
    ldh add file \
      -c "$OWNER_CERT_KEYSTORE" \
      -p "$OWNER_CERT_PWD" \
      --title "File" \
      --file "$file" \
      --content-type "application/octet-stream" \
      "$doc"
    echo "${END_USER_BASE_URL}uploads/$(shasum -a 1 "$file" | awk '{print $1}')"
}

granted=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Granted" \
  --container "$END_USER_BASE_URL")
other=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Not granted" \
  --container "$END_USER_BASE_URL")

granted_file=$(upload "$granted" "$work/granted" | tail -n 1)
other_file=$(upload "$other" "$work/other" | tail -n 1)

ldh admin create authorization \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --label "Read one document" \
  --agent "$AGENT_URI" \
  --to "$granted" \
  --read \
  "$ADMIN_BASE_URL" > /dev/null

status_of()
{
    curl -k -s -o /dev/null -w "%{http_code}" -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" "$1"
}

status=$(status_of "$granted")
echo "DEBUG: the granted document: Expected: $STATUS_OK Got: $status"
[ "$status" = "$STATUS_OK" ]

status=$(status_of "$granted_file")
echo "DEBUG: a file uploaded into it: Expected: $STATUS_OK Got: $status"
[ "$status" = "$STATUS_OK" ]

status=$(status_of "$other_file")
echo "DEBUG: a file uploaded into another document: Expected: $STATUS_FORBIDDEN Got: $status"
[ "$status" = "$STATUS_FORBIDDEN" ]
