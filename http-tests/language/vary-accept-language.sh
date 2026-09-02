#!/usr/bin/env bash
set -euo pipefail

# An HTML representation differs by the reader's language, so the response has to say so or a shared cache will hand one
# reader's page to another. This is the header the caches downstream key on, and the reason two readers can be served from
# the same URL at all.

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

curl -i -k -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: text/html" \
  -H "Accept-Language: en" \
  "$END_USER_BASE_URL" \
| tr -d '\r' \
| grep -i "^Vary:" \
| grep -qi "Accept-Language"

# the same URL must survive two readers in sequence through the caches in front of it

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

fetch_language()
{
    curl -i -k -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: text/html" \
      -H "Accept-Language: $1" \
      "$END_USER_BASE_URL" \
    | tr -d '\r' \
    | grep -i "^Content-Language:" \
    | sed 's/^Content-Language: *//i' || true
}

[ "$(fetch_language "en")" = "en-US" ]
[ "$(fetch_language "es")" = "es-ES" ]
[ "$(fetch_language "en")" = "en-US" ]
