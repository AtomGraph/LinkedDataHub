#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Test that nginx gzip compression is active for RDF/XML dynamic content.
# Create an item, append enough data to exceed gzip_min_length, then retrieve it as RDF/XML.

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

item=$(create-item.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Gzip test item" \
  --slug "gzip-test" \
  --container "$END_USER_BASE_URL")

printf '@prefix ex: <http://example.org/> .\n
<> ex:prop1 "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore." ;\n
   ex:prop2 "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo." ;\n
   ex:prop3 "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur." ;\n
   ex:prop4 "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est." .\n' \
| post.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  -t "text/turtle" \
  "$item"

response=$(curl -k -s -D - -o /dev/null \
  -H "Accept-Encoding: gzip" \
  -H "Accept: application/rdf+xml" \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  "$item")

if ! echo "$response" | grep -qi "Content-Encoding: gzip"; then
  echo "Content-Encoding: gzip not found on RDF/XML response"
  exit 1
fi

if ! echo "$response" | grep -q "HTTP/.* 200"; then
  echo "RDF/XML request did not return 200 OK"
  exit 1
fi
