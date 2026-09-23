#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
clear_ontology

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
