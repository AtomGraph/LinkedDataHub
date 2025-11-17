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

# LNK-009: Test that RFC 1918 private addresses are blocked via SSRF protection
# Test Class A (10.0.0.0/8)

http_status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: application/n-triples' \
  --data-urlencode "uri=http://10.0.0.1:8080/test" \
  "$END_USER_BASE_URL" || true)

if [ "$http_status" != "403" ]; then
    echo "Expected HTTP 403 Forbidden for 10.0.0.1 access, got: $http_status"
    exit 1
fi

# Test Class B (172.16.0.0/12)

http_status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: application/n-triples' \
  --data-urlencode "uri=http://172.16.0.1:8080/test" \
  "$END_USER_BASE_URL" || true)

if [ "$http_status" != "403" ]; then
    echo "Expected HTTP 403 Forbidden for 172.16.0.1 access, got: $http_status"
    exit 1
fi

# Test Class C (192.168.0.0/16)

http_status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -G \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H 'Accept: application/n-triples' \
  --data-urlencode "uri=http://192.168.1.1:8080/test" \
  "$END_USER_BASE_URL" || true)

if [ "$http_status" != "403" ]; then
    echo "Expected HTTP 403 Forbidden for 192.168.1.1 access, got: $http_status"
    exit 1
fi
