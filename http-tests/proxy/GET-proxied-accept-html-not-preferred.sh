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

# Regression: when a client lists application/xhtml+xml (or text/html) in Accept at a
# LOWER q-value than another supported type, the proxy must treat the request as
# API-client intent and forward — not as browser navigation that wants the app shell.
# Previously, ProxyRequestFilter bypassed on anyMatch(HTML or XHTML in Accept) without
# checking q-rank, so it false-fired on any Accept that mentioned HTML at all and
# returned the local XHTML shell instead of the proxied response.

accept_header='application/xml, text/xml;q=0.9, application/xhtml+xml;q=0.8, */*;q=0.7'

content_type=$(curl -k -f -s -G -w "%{content_type}" -o /dev/null \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: $accept_header" \
  --data-urlencode "uri=${END_USER_BASE_URL}" \
  "$END_USER_BASE_URL")

echo "DEBUG: Accept:        $accept_header"
echo "DEBUG: Content-Type:  $content_type"
echo "DEBUG: Expected:      not application/xhtml+xml or text/html (proxy must forward, not return local app shell)"

# fail (exit 1) if the response is the local app shell instead of the proxied content
echo "$content_type" | grep -qvE '^(application/xhtml\+xml|text/html)\b'
