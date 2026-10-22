#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# documents are a directly identified graph store (GSP 4.1): a ?graph= (indirect identification) on a document
# request is refused, instead of being ignored and the payload merged into the document the request URI names

root_etag=$(etag "$END_USER_BASE_URL" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")

status=$(
curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "If-Match: $root_etag" \
  -H "Content-Type: application/n-triples" \
  --data-binary @- \
  "${END_USER_BASE_URL}?graph=${END_USER_BASE_URL}foo/" <<EOF
<${END_USER_BASE_URL}graph-param-subject> <http://example.com/predicate> "graph param object" .
EOF
)

echo "DEBUG: POST ?graph= expected: $STATUS_BAD_REQUEST"
echo "DEBUG: POST ?graph= got: $status"

if [ "$status" != "$STATUS_BAD_REQUEST" ]; then
  echo "POST with ?graph= did not return $STATUS_BAD_REQUEST"
  exit 1
fi

# ?default is refused the same way

status=$(
curl -k -w "%{http_code}\n" -o /dev/null -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}?default"
)

echo "DEBUG: GET ?default expected: $STATUS_BAD_REQUEST"
echo "DEBUG: GET ?default got: $status"

if [ "$status" != "$STATUS_BAD_REQUEST" ]; then
  echo "GET with ?default did not return $STATUS_BAD_REQUEST"
  exit 1
fi

# the root document is untouched

root_ntriples=$(
curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL"
)

if echo "$root_ntriples" | grep -q "graph-param-subject"; then
  echo "DEBUG: root document:"
  echo "$root_ntriples"
  echo "The POST with ?graph= was merged into the root document"
  exit 1
fi

root_etag_after=$(etag "$END_USER_BASE_URL" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")

echo "DEBUG: root ETag before: $root_etag"
echo "DEBUG: root ETag after: $root_etag_after"

if [ "$root_etag" != "$root_etag_after" ]; then
  echo "The root document's ETag changed"
  exit 1
fi
