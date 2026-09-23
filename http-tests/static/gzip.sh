#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
clear_ontology

# Test that nginx gzip compression is active for static JSON (SEF file)

response=$(curl -k -s -D - -o /dev/null \
  -H "Accept-Encoding: gzip" \
  "${END_USER_BASE_URL}static/com/atomgraph/linkeddatahub/xsl/client.xsl.sef.json")

if ! echo "$response" | grep -qi "Content-Encoding: gzip"; then
  echo "Content-Encoding: gzip not found on client.xsl.sef.json"
  exit 1
fi

if ! echo "$response" | grep -q "HTTP/.* 200"; then
  echo "client.xsl.sef.json did not return 200 OK"
  exit 1
fi
