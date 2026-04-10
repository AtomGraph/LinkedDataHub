#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Test that nginx gzip compression is active for RDF/XML dynamic content

response=$(curl -i -k -s \
  -H "Accept-Encoding: gzip" \
  -H "Accept: application/rdf+xml" \
  "$END_USER_BASE_URL")

if ! echo "$response" | grep -qi "Content-Encoding: gzip"; then
  echo "Content-Encoding: gzip not found on RDF/XML response"
  exit 1
fi

if ! echo "$response" | grep -q "HTTP/.* 200"; then
  echo "RDF/XML request did not return 200 OK"
  exit 1
fi
