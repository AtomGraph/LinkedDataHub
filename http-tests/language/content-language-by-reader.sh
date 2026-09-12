#!/usr/bin/env bash
set -euo pipefail

# Content-Language names the language the page was composed in, which is the first of the reader's accepted languages that
# the UI translation bundle actually has - not the reader's top preference. The bundle ships English and Spanish, so a
# Lithuanian or German reader gets an honest en rather than their own request echoed back at them. What is published is the
# shortest tag the bundle justifies: its keys are en-US and es-ES, but neither region distinguishes anything.

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

response()
{
    curl -i -k -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: text/html" \
      "$@" \
      "$END_USER_BASE_URL" \
    | tr -d '\r'
}

assert_language()
{
    local accept_language="$1"
    local expected="$2"
    local response actual

    if [ -n "$accept_language" ]; then
        response=$(response -H "Accept-Language: $accept_language")
    else
        response=$(response)
    fi

    # an error page is rendered through the same stylesheet and carries a Content-Language of its own, so every probe
    # confirms this is the document rather than a failure that happens to be labelled
    echo "$response" | grep -qE "^HTTP/[0-9.]+ 200"

    actual=$(echo "$response" | grep -i "^Content-Language:" | sed 's/^Content-Language: *//i' || true)

    [ "$actual" = "$expected" ]
}

# the bundle keys are region-qualified while browsers send primary subtags, so matching is RFC 4647 Basic
# Filtering - but the published tag drops a region that distinguishes nothing, per BCP 47

assert_language "en-US,en;q=0.9,da;q=0.8,lt;q=0.7" "en"
assert_language "en" "en"
assert_language "es" "es"

# preference order decides between two languages the bundle has, rather than bundle order

assert_language "es,en;q=0.9" "es"
assert_language "en,es;q=0.9" "en"

# the bundle has no Lithuanian, so the page is composed in the next language it does have

assert_language "lt,en-US;q=0.9,en;q=0.8" "en"

# none of the reader's languages are available: fall back rather than claim a language the page is not in

assert_language "de,fr;q=0.9" "en"

# no preference expressed at all

assert_language "" "en"
