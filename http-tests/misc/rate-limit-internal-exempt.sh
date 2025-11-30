#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Internal requests from Docker containers (RFC 1918 private IPs) should be exempt from rate limiting.
# Execute curl from inside the linkeddatahub container to simulate internal loopback requests.
# Make 50 rapid parallel requests and verify none return 429 (Too Many Requests).
# External requests would trigger rate limiting at 15 req/s with burst=30.

# Use xargs -P to send parallel requests (same method that triggers 429 for external requests)
RESPONSE=$(docker exec linkeddatahub-linkeddatahub-1 bash -c 'seq 1 50 | xargs -P 50 -I {} sh -c "curl -k -w \"%{http_code}\n\" -o /dev/null -s https://nginx:9443/ -H \"Host: localhost\" 2>/dev/null"' | grep -c "^429$" || true)

# Default to 0 if grep found nothing
RESPONSE=${RESPONSE:-0}

if [ "$RESPONSE" -gt 0 ]; then
    echo "FAIL: $RESPONSE internal requests were rate-limited (429)"
    exit 1
fi
