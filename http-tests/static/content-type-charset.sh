#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
clear_ontology

# Every text type served from /static declares UTF-8.
#
# Tomcat's default mime mappings name no charset, and a response that does not name one is decoded
# by the client's fallback encoding - windows-1252 in a browser tab - which breaks every multi-byte
# character apart ("—" arrives as "â€""). A stylesheet or script loaded FROM a page escapes this by
# inheriting the referencing document's encoding, so the app renders correctly while the files
# themselves do not, and the defect stays invisible until someone opens one directly. The mappings
# live in src/main/webapp/WEB-INF/web.xml.
#
# .map carries no charset on purpose: JSON is UTF-8 by definition (RFC 8259). .rdf carries none
# either - an XML document declares its own encoding, and a header parameter would be a second
# source of truth that could disagree with it (RFC 7303).

declare -a expectations=(
    "com/atomgraph/linkeddatahub/css/ldh.css|text/css;charset=UTF-8"
    "com/atomgraph/linkeddatahub/xsl/client.xsl|text/xsl;charset=UTF-8"
    "com/atomgraph/linkeddatahub/js/SPARQL.js|text/javascript;charset=UTF-8"
    "com/atomgraph/linkeddatahub/js/saxon-js/LICENSE.txt|text/plain;charset=UTF-8"
    "com/atomgraph/linkeddatahub/css/ol.css.map|application/json"
)

failures=0

for expectation in "${expectations[@]}"
do
    path="${expectation%%|*}"
    expected="${expectation#*|}"

    headers=$(curl -k -s -D - -o /dev/null "${END_USER_BASE_URL}static/${path}")
    status=$(grep -o "HTTP/[0-9.]* [0-9]*" <<< "$headers" | tail -1 | grep -o "[0-9]*$")
    # the header name is case-insensitive and the value may carry whitespace around the parameter
    actual=$(grep -i "^content-type:" <<< "$headers" | tail -1 | cut -d: -f2- | tr -d " \r")

    echo "DEBUG: ${path}"
    echo "DEBUG:   status:   ${status}"
    echo "DEBUG:   expected: ${expected}"
    echo "DEBUG:   actual:   ${actual}"

    if [ "$status" != "200" ]
    then
        echo "Static file did not return 200 OK: ${path} (got ${status})"
        failures=$((failures + 1))
        continue
    fi

    if [ "$actual" != "$expected" ]
    then
        echo "Wrong Content-Type on ${path}: expected '${expected}', got '${actual}'"
        failures=$((failures + 1))
    fi
done

if [ "$failures" -ne 0 ]
then
    echo "${failures} static file(s) served with the wrong Content-Type"
    exit 1
fi
