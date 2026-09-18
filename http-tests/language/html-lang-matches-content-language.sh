#!/usr/bin/env bash
set -euo pipefail

# The header and the document have to agree about what language the page is in. They do because both read the same
# computation: the stylesheet takes the root lang straight from Content-Language rather than from the request. A reader whose
# language the bundle lacks is the case that used to disagree - the header said nothing while the document claimed lt.

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

assert_agrees()
{
    local expected="$2"
    local headers body header document

    headers=$(mktemp)

    # XHTML is the same rendering as text/html but well-formed, so the document can be queried with XPath rather than
    # matched as text - attribute order is a serialization detail and nothing here depends on it
    body=$(curl -k -s \
      -D "$headers" \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: application/xhtml+xml" \
      -H "Accept-Language: $1" \
      "$END_USER_BASE_URL")

    # an error page is rendered through the same stylesheet and agrees with itself just as happily, so confirm this is the
    # document before comparing the two
    head -1 "$headers" | grep -qE "^HTTP/[0-9.]+ 200"

    header=$(tr -d '\r' < "$headers" | grep -i "^Content-Language:" | sed 's/^Content-Language: *//i' || true)
    rm -f "$headers"

    document=$(echo "$body" | xmllint --xpath 'string(/*[local-name() = "html"]/@lang)' - 2> /dev/null || true)

    [ "$header" = "$expected" ] && [ "$document" = "$expected" ]
}

assert_agrees "en" "en"
assert_agrees "es" "es"

# the bundle has no Lithuanian and no German: the root must not claim a language the page is not written in

assert_agrees "lt,en;q=0.9" "en"
assert_agrees "de" "en"
