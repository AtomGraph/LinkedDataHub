#!/usr/bin/env bash
set -euo pipefail

# Test that accessing a non-configured dataspace returns 404, not 500

# Try to access admin on non-existent test.localhost dataspace
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -H "Accept: application/n-triples" \
  "https://admin.non-existing.localhost:4443/" \
| grep -q "$STATUS_NOT_FOUND"

# Try to access end-user on non-existent test.localhost dataspace
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -H "Accept: application/n-triples" \
  "https://non-existing.localhost:4443/" \
| grep -q "$STATUS_NOT_FOUND"
