#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A path carrying a parameter (;) is refused with 400. --path-as-is keeps curl from normalising the path

body=$(mktemp)

status=$(curl -k -s --path-as-is -o "$body" -w "%{http_code}" \
  "${END_USER_BASE_URL}static/..;/")

echo "DEBUG: GET static/..;/ Expected: $STATUS_BAD_REQUEST  Got: $status"
if [ "$status" != "$STATUS_BAD_REQUEST" ]; then
  exit 1
fi

# the answer is the proxy's refusal, not the application shell rendered for the root document
if grep -q 'about="' "$body"; then
  echo "DEBUG: the body is the application shell:"
  head -c 500 "$body"
  exit 1
fi

rm -f "$body"

# the same for a path parameter on any other path, with or without a client certificate

status=$(curl -k -s --path-as-is -o /dev/null -w "%{http_code}" \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  "${END_USER_BASE_URL};x=y/")

echo "DEBUG: GET ;x=y/ Expected: $STATUS_BAD_REQUEST  Got: $status"
if [ "$status" != "$STATUS_BAD_REQUEST" ]; then
  exit 1
fi

# an encoded semicolon is data, not a path parameter, and is not refused for it

status=$(curl -k -s --path-as-is -o /dev/null -w "%{http_code}" \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}a%3Bb/")

echo "DEBUG: GET a%3Bb/ Expected: not $STATUS_BAD_REQUEST  Got: $status"
if [ "$status" = "$STATUS_BAD_REQUEST" ]; then
  exit 1
fi

# nor is a semicolon in the query string

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/sparql-results+xml" \
  "${END_USER_BASE_URL}sparql?query=SELECT%20*%20%7B%20%3Fs%20%3Fp%20%3Fo%20%7D%20LIMIT%201&x=a;b")

echo "DEBUG: GET sparql?...&x=a;b Expected: $STATUS_OK  Got: $status"
if [ "$status" != "$STATUS_OK" ]; then
  exit 1
fi
