#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# HEAD is the only way to learn an entity tag, and a write to a document that already exists has to quote
# one. Mapping HEAD to acl:Read alone therefore made acl:Write mean acl:Write AND acl:Read: an agent granted
# write access and nothing else could not obtain a validator, so it could not write at all. HEAD is answered
# for any mode the agent holds; GET still needs acl:Read, and content is what GET returns.

# access is unauthorized before any authorization exists

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -I \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| grep -q "$STATUS_FORBIDDEN"

# grant acl:Write and nothing else

ldh admin create authorization \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --label "Write-only authorization" \
  --agent "$AGENT_URI" \
  --to "$END_USER_BASE_URL" \
  --write

# the writer can now read the validator it has to quote

response=$(curl -k -s -D - -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -I \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL")

status=$(printf '%s' "$response" | sed -En 's|^HTTP/[0-9.]+ ([0-9]+).*$|\1|p' | tail -1)
echo "DEBUG: HEAD as a write-only agent. Expected: $STATUS_OK Got: $status"
[ "$status" = "$STATUS_OK" ] || exit 1

etag=$(printf '%s' "$response" | grep -i '^etag:' | tr -d '\r' | sed -En 's/^[Ee][Tt][Aa][Gg]: (.*)$/\1/p')
echo "DEBUG: HEAD carries ETag: ${etag:-<none>}"
[ -n "$etag" ] || exit 1

# but not when the graph last changed: the entity tag is a hash of the graph, every write stamps dct:modified
# into it at millisecond precision, and Last-Modified would narrow a guess at the content to the second.
# Content-Length is not asserted on - Jersey computes it after the response filter and it gives away nothing
# the tag has not already, since confirming content by its hash tells you its length as well.

if grep -qi '^last-modified:' <<< "$response"; then
    echo "DEBUG: a non-reader's HEAD disclosed Last-Modified" >&2
    exit 1
fi

# GET is still refused: content needs acl:Read

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -G \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL" \
| grep -q "$STATUS_FORBIDDEN"

# and the write the validator was for succeeds

root_ntriples=$(ldh get \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --accept 'application/n-triples' \
  "$END_USER_BASE_URL")

status=$(printf '%s' "$root_ntriples" | curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-Match: $etag" \
  --data-binary @- \
  "$END_USER_BASE_URL")

echo "DEBUG: conditional PUT as a write-only agent. Expected: $STATUS_PUT_SUCCESS Got: $status"
[[ "$status" =~ ^($STATUS_PUT_SUCCESS)$ ]] || exit 1
