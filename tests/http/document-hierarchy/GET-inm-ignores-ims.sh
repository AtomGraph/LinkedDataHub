#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# RFC 9110 13.2.2: when If-None-Match is present, If-Modified-Since is not evaluated. A GET whose tag matches is
# answered 304 whatever date it also sends - here one long before the document was last modified, which on its own
# would ask for the full response

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/readers/"

etag=$(etag "$END_USER_BASE_URL" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")

status=$(
curl -k -w "%{http_code}" -o /dev/null -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  -H "If-None-Match: ${etag}" \
  -H "If-Modified-Since: Mon, 01 Jan 2001 00:00:00 GMT" \
  "$END_USER_BASE_URL")

echo "DEBUG: If-None-Match: $etag  Expected: $STATUS_NOT_MODIFIED  Got: $status"
[ "$status" = "$STATUS_NOT_MODIFIED" ]
