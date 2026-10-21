#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# An upload is access-controlled: its content never changes (it is addressed by its hash), but who may read it does, so
# it may be kept by the reader's own cache only, never by a shared one

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

filename=$(mktemp)
dd if=/dev/urandom of="$filename" bs=1 count=1024 2> /dev/null

file_doc=$(ldh create item \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Random file" \
  --container "$END_USER_BASE_URL")

ldh add file \
  -c "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  --title "Random file" \
  --file "$filename" \
  --content-type "application/octet-stream" \
  "$file_doc"

sha1sum=$(shasum -a 1 "$filename" | awk '{print $1}')
rm -f "$filename"
file="${END_USER_BASE_URL}uploads/${sha1sum}"

cache_control=$(curl -k -s -f -D - -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  "$file" \
| grep -i '^cache-control:' | tr -d '\r' || true)

echo "DEBUG: GET upload Expected: Cache-Control with private and without public  Got: $cache_control"
if ! grep -qi 'private' <<< "$cache_control"; then
  exit 1
fi
if grep -qi 'public' <<< "$cache_control"; then
  exit 1
fi
