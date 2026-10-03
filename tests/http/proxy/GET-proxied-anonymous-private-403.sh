#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Regression: the proxy's upstream request carried the platform's own client certificate whether
# or not the caller was authenticated, so a document nobody had granted to anonymous readers was
# readable by anyone who asked for it through the proxy - the origin was answering the secretary.
# The origin's refusal is the reader's refusal: an anonymous proxied read of a private document is
# 403, and the 403 asserts no agent either.

# a document nobody but the owner may read

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --title "Proxied private document" \
  --slug "proxied-private-$(date +%s)" \
  --container "$END_USER_BASE_URL")

# through the admin origin's proxy, so the request crosses origins and is forwarded

response_headers=$(mktemp)

status=$(curl -k -s -G \
  -o /dev/null \
  -w "%{http_code}" \
  -D "$response_headers" \
  -H 'Accept: application/n-triples' \
  --data-urlencode "uri=${item}" \
  "$ADMIN_BASE_URL")

cat "$response_headers"

if ! echo "$status" | grep -qE "^($STATUS_UNAUTHORIZED|$STATUS_FORBIDDEN)$"; then
    echo "Expected $STATUS_UNAUTHORIZED or $STATUS_FORBIDDEN for the private document, got $status"
    exit 1
fi

if grep -qi "rel=http://www.w3.org/ns/auth/acl#agent" "$response_headers"; then
    echo "An anonymous proxied read asserts an agent"
    exit 1
fi

rm "$response_headers"
