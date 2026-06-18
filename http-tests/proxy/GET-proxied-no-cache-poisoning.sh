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

# Step C: authenticated owner fetches the admin URL directly with cert at TLS,
# Accept: application/rdf+xml. The Client-Cert header reaches varnish-frontend
# (nginx-forwarded). The backend stamps acl#agent into the Link header for the
# authenticated 200. varnish-frontend must NOT cache this response — its hash
# key ignores identity, so a subsequent anonymous request would replay the 200.

purge_cache "$FRONTEND_VARNISH_SERVICE"

curl -k -f -s -o /dev/null \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/rdf+xml' \
  "${ADMIN_BASE_URL}"

# Step D: anonymous direct fetch of the same URL. With the fix in place
# (Client-Cert + non-/static/ path → pass in vcl_recv), Step C didn't store
# anything, so this reaches the backend anonymously and gets 403.

response=$(curl -k -s -i -H 'Accept: application/rdf+xml' "${ADMIN_BASE_URL}")

status=$(printf '%s\n' "$response" | awk 'NR==1{print $2}' | tr -d '\r')
link_leak=$(printf '%s\n' "$response" | tr -d '\r' | grep -i '^link:' | grep -c 'acl#agent' || true)

if [ "$status" != "$STATUS_FORBIDDEN" ]; then
    echo "[Client-Cert path] Expected $STATUS_FORBIDDEN anonymous, got: $status"
    printf '%s\n' "$response" | head -40
    exit 1
fi

if [ "$link_leak" != "0" ]; then
    echo "[Client-Cert path] Anonymous response leaks acl#agent in Link header (cache poisoning):"
    printf '%s\n' "$response" | grep -i '^link:'
    exit 1
fi
