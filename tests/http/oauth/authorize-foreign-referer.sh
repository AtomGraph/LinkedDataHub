#!/usr/bin/env bash
set -euo pipefail

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# The state cookie stores the referer only if it is on one of this instance's dataspaces, and the dataspace base
# otherwise. The cookie is Secure, HttpOnly and SameSite=Lax.
# Needs a configured Google OAuth client; skipped otherwise.

authorize="${END_USER_BASE_URL}oauth2/authorize/google"

response_headers=$(mktemp)

status=$(curl -k -s -G \
  -o /dev/null \
  -w "%{http_code}" \
  -D "$response_headers" \
  --data-urlencode "referer=https://evil.example/" \
  "$authorize")

echo "DEBUG: status: $status"
cat "$response_headers"

if [ "$status" != "$STATUS_SEE_OTHER" ]; then
    echo "SKIPPED: no Google OAuth client configured (${authorize} returned $status)"
    rm "$response_headers"
    exit 0
fi

# referer and expected stored value, one pair per case
cases=(
  "https://evil.example/" "$END_USER_BASE_URL"
  "javascript:alert(1)" "$END_USER_BASE_URL"
  "//evil.example/" "$END_USER_BASE_URL"
  "${END_USER_BASE_URL}some/document/" "${END_USER_BASE_URL}some/document/"
)

for (( i=0; i<${#cases[@]}; i+=2 )); do
    referer="${cases[$i]}"
    expected="${cases[$((i+1))]}"

    curl -k -s -G \
      -o /dev/null \
      -D "$response_headers" \
      --data-urlencode "referer=${referer}" \
      "$authorize"

    state_cookie=$(grep -i '^Set-Cookie: LinkedDataHub.state=' "$response_headers" | tr -d '\r')
    echo "DEBUG: referer: $referer"
    echo "DEBUG: Set-Cookie: $state_cookie"

    if [ -z "$state_cookie" ]; then
        echo "DEBUG: no LinkedDataHub.state cookie set"
        exit 1
    fi

    # the value is Base64 of "<state>;<referer>"
    value=$(echo "$state_cookie" | cut -d '=' -f 2- | cut -d ';' -f 1 | tr -d '"')
    decoded=$(printf '%s' "$value" | openssl base64 -d -A)
    stored="${decoded#*;}"

    echo "DEBUG: expected: $expected"
    echo "DEBUG: got: $stored"

    if [ "$stored" != "$expected" ]; then
        echo "DEBUG: the state cookie stores an unexpected referer"
        exit 1
    fi

    for attribute in "Secure" "HttpOnly" "SameSite=Lax"; do
        if ! echo "$state_cookie" | grep -qi "; *${attribute}"; then
            echo "DEBUG: the state cookie lacks ${attribute}"
            exit 1
        fi
    done
done

rm "$response_headers"
