#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# create container

slug="test"

container=$(create-container.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test" \
  --slug "$slug" \
  --parent "$END_USER_BASE_URL")

# add an explicit read/write authorization for the owner because add-agent-to-group.sh won't work non-existing URI

create-authorization.sh \
-b "$ADMIN_BASE_URL" \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --label "Write base" \
  --agent "$AGENT_URI" \
  --to "$container" \
  --read \
  --write

# store the ETag value

etag_before=$(
  curl -k -i -f -s -G \
    -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
    -H "Accept: application/n-triples" \
  "$container" \
| grep 'ETag' \
| tr -d '\r' \
| sed -En 's/^ETag: (.*)$/\1/p')

# delete the graph only if the ETag value matches

(
curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -X DELETE \
  -H "If-Match: ${etag_before}" \
  "$container"
) \
| grep -q "$STATUS_NO_CONTENT"
