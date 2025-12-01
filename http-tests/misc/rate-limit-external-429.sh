#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# External requests (non-RFC 1918 IPs) should be rate limited.
# Make 50 rapid parallel requests from the host and verify some return 429 (Too Many Requests).
# Rate limit is 15 req/s with burst=30, so parallel requests should trigger 429.

# Use xargs -P to send parallel requests (triggers rate limiting)
RESPONSES=$(seq 1 50 | xargs -P 50 -I {} sh -c "curl -k -w \"%{http_code}\n\" -o /dev/null -s -E \"$OWNER_CERT_FILE\":\"$OWNER_CERT_PWD\" \"$END_USER_BASE_URL\" 2>/dev/null")
RATE_LIMITED=$(echo "$RESPONSES" | grep -c "^429$" || true)

# Default to 0 if grep found nothing
RATE_LIMITED=${RATE_LIMITED:-0}

# Debug output
echo "Rate limited responses (429): $RATE_LIMITED out of 50"
echo "Response codes: $(echo "$RESPONSES" | sort | uniq -c)"

if [ "$RATE_LIMITED" -eq 0 ]; then
    echo "FAIL: No requests were rate-limited (429). Expected some 429 responses for external requests."
    exit 1
fi
