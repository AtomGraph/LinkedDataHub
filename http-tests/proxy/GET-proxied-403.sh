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

# Test that status codes are correctly proxied through
# Generate a random UUID for a non-existing resource
random_uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)
non_existing_uri="${END_USER_BASE_URL}${random_uuid}/"

# Attempt to proxy a non-existing document on the END_USER_BASE_URL
# This should return 403 Forbidden (not found resources return 403 in LinkedDataHub)
http_status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: application/n-triples' \
  --data-urlencode "uri=${non_existing_uri}" \
  "$END_USER_BASE_URL" || true)

# Verify that the proxied status code matches the backend status code (403)
if [ "$http_status" != "403" ]; then
    echo "Expected HTTP 403 Forbidden for non-existing proxied document, got: $http_status"
    exit 1
fi
