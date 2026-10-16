#!/usr/bin/env bash
set -euo pipefail

# requires the credentials secret (docker-compose.versioning.yml), whose GitHub token is $GITHUB_TOKEN. The token lives in
# the context dataset beside the dataspace descriptions; no page may carry it, nor the backend endpoints, since the
# stylesheets only ever see the public dataspace context

if [ -z "${VERSIONING_TEST_REPO:-}" ] || [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "SKIPPED: VERSIONING_TEST_REPO/GITHUB_TOKEN not set"
    exit 0
fi

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

for uri in "$END_USER_BASE_URL" "$ADMIN_BASE_URL" "${END_USER_BASE_URL}context"; do
  for accept in "text/html" "application/rdf+xml"; do
    body=$(curl -k -f -s -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" -H "Accept: $accept" "$uri")

    if echo "$body" | grep -q -F "$GITHUB_TOKEN"; then
      echo "DEBUG: $uri ($accept) contains the GitHub token"
      exit 1
    fi
    if echo "$body" | grep -q -E 'fuseki:3030|atomgraph/core#auth'; then
      echo "DEBUG: $uri ($accept) contains internal wiring:"
      echo "$body" | grep -o -E '.{0,60}(fuseki:3030|atomgraph/core#auth).{0,60}' | head -5
      exit 1
    fi
  done
done
