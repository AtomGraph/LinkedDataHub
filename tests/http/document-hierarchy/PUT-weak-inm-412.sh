#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# RFC 9110 13.2.2: If-None-Match uses the weak comparison function on every method (13.1.2), so a write that names
# the current tag as weak fails with 412 - it asked to proceed only if the representation is not that one

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

etag=$(etag "$END_USER_BASE_URL" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")

# If-Match quotes the current tag too, so the write is not refused with 428 before If-None-Match is evaluated

status=$(
curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-Match: ${etag}" \
  -H "If-None-Match: W/${etag}" \
  --data-binary @- \
  "$END_USER_BASE_URL" <<EOF
<${END_USER_BASE_URL}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/atomgraph/linkeddatahub/default#Root> .
<${END_USER_BASE_URL}> <http://purl.org/dc/terms/title> "Overwritten" .
EOF
)

echo "DEBUG: If-None-Match: W/$etag  Expected: $STATUS_PRECONDITION_FAILED  Got: $status"
[ "$status" = "$STATUS_PRECONDITION_FAILED" ]

# and the document was not overwritten

body=$(
curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$END_USER_BASE_URL")

if echo "$body" | grep -q '"Overwritten"'; then
  echo "DEBUG: the write went through despite the failed precondition"
  exit 1
fi
