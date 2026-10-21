#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Identity comes from the TLS connection, never from a request header. The client sends the owner's certificate - public
# data, without its private key - in the header the proxy uses to forward a verified client certificate, and presents no
# certificate on the connection. The proxy must replace the header on every path, so the request stays anonymous

client_cert=$(openssl x509 -in "$OWNER_CERT_FILE" | python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=""))')

# the root document is readable by its owner only

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL")

echo "DEBUG: anonymous GET root Expected: $STATUS_FORBIDDEN  Got: $status"
if [ "$status" != "$STATUS_FORBIDDEN" ]; then
  exit 1
fi

# through a static path with a path parameter: refused, and never the document

status=$(curl -k -s --path-as-is -o /dev/null -w "%{http_code}" \
  -H "Accept: application/n-triples" \
  -H "Client-Cert: $client_cert" \
  -H "X-Forwarded-Host: ${END_USER_BASE_URL#https://}" \
  "${END_USER_BASE_URL}static/..;/")

echo "DEBUG: GET static/..;/ with a header-only certificate Expected: not $STATUS_OK  Got: $status"
if [ "$status" = "$STATUS_OK" ]; then
  exit 1
fi

# on the document's own path: still anonymous

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -H "Accept: application/n-triples" \
  -H "Client-Cert: $client_cert" \
  "$END_USER_BASE_URL")

echo "DEBUG: GET root with a header-only certificate Expected: $STATUS_FORBIDDEN  Got: $status"
if [ "$status" != "$STATUS_FORBIDDEN" ]; then
  exit 1
fi
