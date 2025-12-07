#!/usr/bin/env bash
set -euo pipefail

# Test Tomcat CorsFilter on static files
# The Tomcat filter only adds CORS headers when Origin header is present

response=$(curl -i -k -s \
  -H "Origin: https://example.com" \
  "${END_USER_BASE_URL}static/com/atomgraph/linkeddatahub/css/bootstrap.css")

# Verify Access-Control-Allow-Origin header is present
if ! echo "$response" | grep -q "Access-Control-Allow-Origin: \*"; then
  echo "CORS header 'Access-Control-Allow-Origin' not found on static file"
  exit 1
fi

# Verify the static file was served successfully
if ! echo "$response" | grep -q "HTTP/.* 200"; then
  echo "Static file request did not return 200 OK"
  exit 1
fi

# Test OPTIONS request on static files

preflight=$(curl -i -k -s \
  -X OPTIONS \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: GET" \
  "${END_USER_BASE_URL}static/com/atomgraph/linkeddatahub/css/bootstrap.css")

# Verify preflight response has CORS headers
if ! echo "$preflight" | grep -q "Access-Control-Allow-Origin: \*"; then
  echo "CORS header 'Access-Control-Allow-Origin' not found in OPTIONS response for static file"
  exit 1
fi
