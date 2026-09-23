#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
clear_ontology

# POST /clear without a uri empties the cache and reloads nothing. The URI was required once, so this
# form is new surface and needs the same authorization the targeted form has: owners only, per the
# full-control authorization in admin.trig. A writer reaching it would be a widening nobody asked for.

ldh admin add agent \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  "${ADMIN_BASE_URL}clear")
expected="$STATUS_FORBIDDEN"
echo "DEBUG: [writer] Expected: $expected"
echo "DEBUG: [writer] Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"

# the owner gets through, and the request is accepted without naming an ontology

actual=$(curl -k -w "%{http_code}" -o /dev/null -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -X POST \
  -H "Accept: text/turtle" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  "${ADMIN_BASE_URL}clear")
expected="$STATUS_OK|$STATUS_NO_CONTENT"
echo "DEBUG: [owner] Expected: $expected"
echo "DEBUG: [owner] Got: $actual"
echo "$actual" | grep -qE "^(${expected})$"
