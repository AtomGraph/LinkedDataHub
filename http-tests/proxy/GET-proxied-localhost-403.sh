#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# add agent to the readers group to be able to read documents

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/readers/"

# LNK-009: Test that localhost is blocked via SSRF protection
# Attempt to access localhost via the proxy
# This should be blocked and return 403 Forbidden

http_status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: application/n-triples' \
  --data-urlencode "uri=http://localhost:8080/test" \
  "$END_USER_BASE_URL" || true)

# Verify that access was forbidden (403)
if [ "$http_status" != "403" ]; then
    echo "Expected HTTP 403 Forbidden for localhost access, got: $http_status"
    exit 1
fi
