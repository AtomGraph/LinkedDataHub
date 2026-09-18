#!/usr/bin/env bash
set -euo pipefail

# Two readers get two different HTML representations of the same document, so the two must not share an entity tag: a
# Spanish reader arriving with the English reader's tag would be told 304 and shown a page in a language they never asked
# for. The RDF representation is the same bytes for both, so its tag has to stay stable across them.

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

etag()
{
    curl -i -k -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: $1" \
      -H "Accept-Language: $2" \
      "$END_USER_BASE_URL" \
    | tr -d '\r' \
    | grep -i "^ETag:" \
    | sed 's/^ETag: *//i' || true
}

html_en=$(etag "text/html" "en")
html_es=$(etag "text/html" "es")

[ -n "$html_en" ]

# two languages must not share one entity tag, or a conditional request would serve the wrong language

[ "$html_en" != "$html_es" ]

# the tag is still stable for one reader, otherwise conditional requests never revalidate

[ "$html_en" = "$(etag "text/html" "en")" ]

status()
{
    curl -k -w "%{http_code}" -o /dev/null -s \
      -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
      -H "Accept: text/html" \
      -H "Accept-Language: $1" \
      -H "If-None-Match: $2" \
      "$END_USER_BASE_URL"
}

# the reader's own tag revalidates, another reader's does not

[ "$(status "en" "$html_en")" = "$STATUS_NOT_MODIFIED" ]
[ "$(status "es" "$html_en")" = "$STATUS_OK" ]

# RDF carries every language at once, so language is not part of its identity

[ "$(etag "application/n-triples" "en")" = "$(etag "application/n-triples" "es")" ]
