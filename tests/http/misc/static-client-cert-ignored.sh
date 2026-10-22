#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A Client-Cert header sent by the client is ignored on every path: identity comes from the TLS connection only

client_cert=$(openssl x509 -in "$OWNER_CERT_FILE" | python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=""))')

# the root document is readable by its owner only

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL")

echo "DEBUG: anonymous GET root Expected: $STATUS_FORBIDDEN  Got: $status"
if [ "$status" != "$STATUS_FORBIDDEN" ]; then
  exit 1
fi

# a static path with a path parameter: never the document

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

# with a Proxy-Secret header of the client's own: still anonymous, the proxy sets that header itself

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -H "Accept: application/n-triples" \
  -H "Client-Cert: $client_cert" \
  -H "Proxy-Secret: not-the-secret" \
  "$END_USER_BASE_URL")

echo "DEBUG: GET root with a header-only certificate and a client Proxy-Secret Expected: $STATUS_FORBIDDEN  Got: $status"
if [ "$status" != "$STATUS_FORBIDDEN" ]; then
  exit 1
fi

# the secret is never echoed back

headers=$(curl -k -s -D - -o /dev/null \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL")

echo "DEBUG: owner GET root Expected: no Proxy-Secret response header"
if grep -qi '^proxy-secret:' <<< "$headers"; then
  echo "DEBUG: Got: $(grep -i '^proxy-secret:' <<< "$headers")"
  exit 1
fi
