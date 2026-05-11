#!/usr/bin/env bash
set -euo pipefail

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
