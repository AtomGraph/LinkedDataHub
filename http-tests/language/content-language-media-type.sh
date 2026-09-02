#!/usr/bin/env bash
set -euo pipefail

# Only a representation whose rendering depends on language gets labelled with one. An RDF representation is byte-identical
# for every reader - its literals carry their own tags and none is dropped - so it is intended for all language audiences,
# which RFC 9110 spells as no Content-Language at all.

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

headers()
{
    curl -i -k -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: $1" \
      -H "Accept-Language: en" \
      "$END_USER_BASE_URL" \
    | tr -d '\r'
}

assert_labelled()
{
    local response actual

    response=$(headers "$1")

    # an error page is rendered through the same stylesheet and carries a Content-Language of its own, so every probe
    # confirms this is the representation rather than a failure that happens to be labelled
    echo "$response" | grep -qE "^HTTP/[0-9.]+ 200"

    actual=$(echo "$response" | grep -i "^Content-Language:" | sed 's/^Content-Language: *//i' || true)

    [ "$actual" = "en-US" ]
}

assert_unlabelled()
{
    local response

    response=$(headers "$1")

    echo "$response" | grep -qE "^HTTP/[0-9.]+ 200"

    ! echo "$response" | grep -qi "^Content-Language:"
}

# both HTML flavours are rendered through the translation bundle and so are composed in one language

assert_labelled "text/html"
assert_labelled "application/xhtml+xml"

assert_unlabelled "application/rdf+xml"
assert_unlabelled "text/turtle"
assert_unlabelled "application/n-triples"
assert_unlabelled "application/ld+json"
