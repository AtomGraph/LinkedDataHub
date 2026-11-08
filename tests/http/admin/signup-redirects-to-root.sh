#!/usr/bin/env bash
set -euo pipefail

purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# Agents are signed up only in the root admin dataspace, the one holding the secretary's WebID, so a WebID outlives any
# other dataspace and no other dataspace's owner can rewrite it. Sign-up on another dataspace's admin redirects there,
# keeping the referer the sign-up returns to.

other_admin_base_url="https://admin.test.localhost:4443/"
referer="https://test.localhost:4443/"
headers=$(mktemp)

status=$(curl -k -s -o /dev/null -w "%{http_code}" -D "$headers" \
  -H "Accept: text/html" \
  --url-query "referer=${referer}" \
  "${other_admin_base_url}sign%20up")
location=$(grep -i '^location:' "$headers" | tr -d '\r' | cut -d' ' -f2)

echo "DEBUG: sign-up on another dataspace. Expected: $STATUS_SEE_OTHER Got: $status"
[ "$status" = "$STATUS_SEE_OTHER" ] || exit 1

expected_location="${ADMIN_BASE_URL}sign%20up?referer=https%3A%2F%2Ftest.localhost%3A4443%2F"
echo "DEBUG: Expected Location: $expected_location"
echo "DEBUG: Got Location: $location"
[ "$location" = "$expected_location" ] || exit 1

# a POST is redirected too, so no agent is created outside root

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "rdf=" \
  "${other_admin_base_url}sign%20up")
echo "DEBUG: sign-up POST on another dataspace. Expected: $STATUS_SEE_OTHER Got: $status"
[ "$status" = "$STATUS_SEE_OTHER" ] || exit 1

# the root admin dataspace serves the sign-up itself

status=$(curl -k -s -o /dev/null -w "%{http_code}" \
  -H "Accept: text/html" \
  "${ADMIN_BASE_URL}sign%20up")
echo "DEBUG: sign-up on root. Expected: $STATUS_OK Got: $status"
[ "$status" = "$STATUS_OK" ] || exit 1

rm -f "$headers"
