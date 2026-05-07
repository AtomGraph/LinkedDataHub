#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the readers group to be able to read documents

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/readers/"

extract_etag() {
    grep -i '^etag:' \
    | tr -d '\r' \
    | sed 's/^[Ee][Tt][Aa][Gg]:[[:space:]]*//'
}

# fetch the end-user root directly to capture its ETag

direct_etag=$(curl --head -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: application/n-triples' \
  "$END_USER_BASE_URL" \
| extract_etag)

# fetch the same document via the admin proxy

proxied_etag=$(curl -G --head -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: application/n-triples' \
  --data-urlencode "uri=${END_USER_BASE_URL}" \
  "$ADMIN_BASE_URL" \
| extract_etag)

if [ -z "$proxied_etag" ]; then
    echo "DEBUG: Expected ETag header on proxied response, got none"
    echo "DEBUG: Direct ETag: $direct_etag"
    exit 1
fi

if [ "$proxied_etag" != "$direct_etag" ]; then
    echo "DEBUG: Proxied ETag does not match direct ETag"
    echo "DEBUG: Direct:   $direct_etag"
    echo "DEBUG: Proxied:  $proxied_etag"
    exit 1
fi
