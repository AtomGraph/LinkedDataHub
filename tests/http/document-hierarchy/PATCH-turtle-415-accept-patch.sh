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

# PATCH accepts SPARQL Update only: a Turtle body is 415 and Accept-Patch names the format PATCH accepts (RFC 5789, section 2.2)

headers=$(curl -k -o /dev/null -s -D - \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PATCH \
  -H "Accept: application/n-triples" \
  -H "If-Match: $(etag "$END_USER_BASE_URL" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD" "application/n-triples")" \
  -H "Content-Type: text/turtle" \
  --data-binary "<http://a> <http://b> <http://c> ." \
  "$END_USER_BASE_URL")

status=$(head -n 1 <<< "$headers" | cut -d ' ' -f 2)
accept_patch=$(grep -i '^accept-patch:' <<< "$headers" | tr -d '\r' || true)
echo "DEBUG: Expected status: $STATUS_UNSUPPORTED_MEDIA"
echo "DEBUG: Got status: $status"
echo "DEBUG: Got: $accept_patch"
[ "$status" = "$STATUS_UNSUPPORTED_MEDIA" ]
grep -qi "application/sparql-update" <<< "$accept_patch"
