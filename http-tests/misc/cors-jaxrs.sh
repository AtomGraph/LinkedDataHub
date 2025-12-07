#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Test JAX-RS CORSFilter on dynamic content (GET request)

response=$(curl -i -k -s \
  -H "Origin: https://example.com" \
  -H "Accept: text/turtle" \
  "$END_USER_BASE_URL")

# Verify Access-Control-Allow-Origin header is present
if ! echo "$response" | grep -q "Access-Control-Allow-Origin: \*"; then
  echo "CORS header 'Access-Control-Allow-Origin' not found in GET response"
  exit 1
fi

# Verify Access-Control-Allow-Methods header is present
if ! echo "$response" | grep -q "Access-Control-Allow-Methods:"; then
  echo "CORS header 'Access-Control-Allow-Methods' not found in GET response"
  exit 1
fi

# Test OPTIONS preflight request

preflight=$(curl -i -k -s \
  -X OPTIONS \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: POST" \
  "$END_USER_BASE_URL")

# Verify preflight response has CORS headers
if ! echo "$preflight" | grep -q "Access-Control-Allow-Origin: \*"; then
  echo "CORS header 'Access-Control-Allow-Origin' not found in OPTIONS response"
  exit 1
fi

# Verify preflight response has Access-Control-Max-Age
if ! echo "$preflight" | grep -q "Access-Control-Max-Age:"; then
  echo "CORS header 'Access-Control-Max-Age' not found in OPTIONS response"
  exit 1
fi

# Verify OPTIONS request returns 204 No Content
if ! echo "$preflight" | grep -q "HTTP/.* 204"; then
  echo "OPTIONS preflight did not return 204 No Content"
  exit 1
fi
