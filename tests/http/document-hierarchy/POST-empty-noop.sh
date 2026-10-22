#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# Appending an empty graph is a no-op (GSP 5.5): it quotes no state because it changes none, so it needs no
# If-Match, and it leaves the document - and so its entity tag - as it was. It used to demand If-Match and then
# stamp dct:modified, rewriting the graph for nothing.

# add agent to the writers group

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
document="${END_USER_BASE_URL}${uuid}/"

status=$(printf '%s' "<${document}> <http://purl.org/dc/terms/title> \"Empty append\" ." | curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X PUT \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  -H "If-None-Match: *" \
  --data-binary @- \
  "$document")

echo "DEBUG: create. Expected: $STATUS_CREATED Got: $status"
[ "$status" = "$STATUS_CREATED" ] || exit 1

before=$(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")

status=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Accept: application/n-triples" \
  -H "Content-Type: application/n-triples" \
  --data-binary "" \
  "$document")

echo "DEBUG: empty POST without If-Match. Expected: $STATUS_NO_CONTENT Got: $status"
[ "$status" = "$STATUS_NO_CONTENT" ] || exit 1

after=$(etag "$document" "$AGENT_CERT_FILE" "$AGENT_CERT_PWD")

echo "DEBUG: entity tag. Expected: $before Got: $after"
[ -n "$before" ] || exit 1
[ "$before" = "$after" ] || exit 1

stored=$(curl -k -f -s -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$document")
echo "DEBUG: stored document: $stored"
modified_count=$(echo "$stored" | grep -c "<${document}> <http://purl.org/dc/terms/modified> " || true)
echo "DEBUG: dct:modified count. Expected: 0 Got: $modified_count"
[ "$modified_count" -eq 0 ] || exit 1
