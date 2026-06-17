#!/usr/bin/env bash
set -euo pipefail

# Regression: ProxyRequestFilter's server-side fetch attaches On-Behalf-Of
# (via WebIDDelegationFilter), and the backend response carries the asserted
# agent's WebID in the Link header (acl#agent). varnish-frontend must not
# cache that response under a URL-keyed entry — otherwise a subsequent
# anonymous request to the same URL+Accept replays the cached 200 and reads
# back the previous agent's identity (and inherits whatever ACL grant they
# had).

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Step A: authenticated owner fires a proxy request from the end-user
# dataspace to the admin dataspace. This triggers WebIDDelegationFilter →
# On-Behalf-Of on the server-side hop into varnish-frontend.

curl -k -f -s -o /dev/null \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -G \
  -H 'Accept: application/rdf+xml' \
  --data-urlencode "uri=${ADMIN_BASE_URL}" \
  "${END_USER_BASE_URL}"

# Step B: anonymous direct request to the admin URL with the same Accept.
# If the cache was poisoned in Step A, this returns 200 with the owner's
# WebID in the Link header. Expected after the fix: varnish-frontend should
# pass on On-Behalf-Of and store nothing, so this goes to the backend
# anonymously and gets 403.

response=$(curl -k -s -i -H 'Accept: application/rdf+xml' "${ADMIN_BASE_URL}")

status=$(printf '%s\n' "$response" | awk 'NR==1{print $2}' | tr -d '\r')
link_leak=$(printf '%s\n' "$response" | tr -d '\r' | grep -i '^link:' | grep -c 'acl#agent' || true)

if [ "$status" != "$STATUS_FORBIDDEN" ]; then
    echo "Expected $STATUS_FORBIDDEN anonymous, got: $status"
    printf '%s\n' "$response" | head -40
    exit 1
fi

if [ "$link_leak" != "0" ]; then
    echo "Anonymous response leaks acl#agent in Link header (cache poisoning):"
    printf '%s\n' "$response" | grep -i '^link:'
    exit 1
fi
