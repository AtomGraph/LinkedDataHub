#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# A write answers with no body, so an Accept that names no RDF syntax has nothing to refuse: the write is not
# answered 406 (GSP 5.3, 5.4; RFC 9110 12.5.1). With no variant selected, If-Match holds when it names the
# current tag of any variant - here the N-Triples one the client read.

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
document="${END_USER_BASE_URL}${uuid}/"

status=$(printf '%s' "<${document}> <http://purl.org/dc/terms/title> \"Unnegotiable\" ." | curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-None-Match: *" \
  --data-binary @- \
  "$document")

echo "DEBUG: create. Expected: $STATUS_CREATED Got: $status"
[ "$status" = "$STATUS_CREATED" ] || exit 1

# a stale tag still fails

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X DELETE \
  -H "Accept: application/sparql-results+json" \
  -H 'If-Match: "0000000000000000"' \
  "$document")

echo "DEBUG: DELETE with a stale tag. Expected: $STATUS_PRECONDITION_FAILED Got: $status"
[ "$status" = "$STATUS_PRECONDITION_FAILED" ] || exit 1

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X DELETE \
  -H "Accept: application/sparql-results+json" \
  -H "If-Match: $(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")" \
  "$document")

echo "DEBUG: DELETE accepting no RDF syntax. Expected: $STATUS_NO_CONTENT Got: $status"
[ "$status" = "$STATUS_NO_CONTENT" ] || exit 1

# a typeless URL matches no class-level authorization, so a missing document reads 403 rather than 404

status=$(curl -k -w "%{http_code}" -o /dev/null -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$document")
echo "DEBUG: the document is gone. Expected: $STATUS_FORBIDDEN or $STATUS_NOT_FOUND Got: $status"
[[ "$status" =~ ^($STATUS_FORBIDDEN|$STATUS_NOT_FOUND)$ ]] || exit 1
