#!/usr/bin/env bash
set -euo pipefail

# Test that nginx gzip compression is active for static JSON (SEF file)

response=$(curl -i -k -s \
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
