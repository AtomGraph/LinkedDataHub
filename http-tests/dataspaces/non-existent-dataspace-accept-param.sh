#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
clear_ontology

# Regression: ?accept= param must be honoured even when the dataspace does not exist

# admin app
content_type=$(curl -k -s -G -w "%{content_type}" -o /dev/null \
  --data-urlencode "accept=text/turtle" \
  "https://admin.non-existing.localhost:4443/")

echo "$content_type" | grep -q "text/turtle"

# end-user app
content_type=$(curl -k -s -G -w "%{content_type}" -o /dev/null \
  --data-urlencode "accept=text/turtle" \
  "https://non-existing.localhost:4443/")

echo "$content_type" | grep -q "text/turtle"
