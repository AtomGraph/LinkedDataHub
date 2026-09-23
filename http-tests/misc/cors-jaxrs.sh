#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
clear_ontology

# Test nginx CORS headers on dynamic content (GET request)

# Every assertion reads its response from a here-string rather than piping an echo into grep -q: the headers tested for
# are at the top of a response that also carries a body, so grep matches and closes the pipe with the body still
# unwritten, and under `set -o pipefail` the SIGPIPE'd echo fails the pipeline on a response that was correct.

response=$(curl -i -k -s \
  -H "Origin: https://example.com" \
  -H "Accept: text/turtle" \
  "$END_USER_BASE_URL")

# Verify Access-Control-Allow-Origin header is present
if ! grep -q "Access-Control-Allow-Origin: \*" <<< "$response"; then
  echo "CORS header 'Access-Control-Allow-Origin' not found in GET response"
  exit 1
fi

# Verify Access-Control-Allow-Methods header is present
if ! grep -q "Access-Control-Allow-Methods:" <<< "$response"; then
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
if ! grep -q "Access-Control-Allow-Origin: \*" <<< "$preflight"; then
  echo "CORS header 'Access-Control-Allow-Origin' not found in OPTIONS response"
  exit 1
fi

# Verify preflight response has Access-Control-Max-Age
if ! grep -q "Access-Control-Max-Age:" <<< "$preflight"; then
  echo "CORS header 'Access-Control-Max-Age' not found in OPTIONS response"
  exit 1
fi

# Verify OPTIONS request returns 204 No Content
if ! grep -q "HTTP/.* 204" <<< "$preflight"; then
  echo "OPTIONS preflight did not return 204 No Content"
  exit 1
fi
