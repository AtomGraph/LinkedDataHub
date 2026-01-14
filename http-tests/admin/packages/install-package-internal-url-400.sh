#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Test SSRF protection: package-uri with link-local address (169.254.0.0/16) should return 400 Bad Request
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=http://169.254.1.1/package#this" \
  "${ADMIN_BASE_URL}packages/install" \
| grep -q "$STATUS_BAD_REQUEST"

# Test SSRF protection: package-uri with private class A address (10.0.0.0/8) should return 400 Bad Request
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=http://10.0.0.1/package#this" \
  "${ADMIN_BASE_URL}packages/install" \
| grep -q "$STATUS_BAD_REQUEST"

# Test SSRF protection: package-uri with private class B address (172.16.0.0/12) should return 400 Bad Request
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=http://172.16.0.0/package#this" \
  "${ADMIN_BASE_URL}packages/install" \
| grep -q "$STATUS_BAD_REQUEST"

# Test SSRF protection: package-uri with private class C address (192.168.0.0/16) should return 400 Bad Request
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "package-uri=http://192.168.1.1/package#this" \
  "${ADMIN_BASE_URL}packages/install" \
| grep -q "$STATUS_BAD_REQUEST"
