#!/usr/bin/env bash
set -euo pipefail

# RDF carries language per literal, HTML per element, so every rendered value declares its own rather than inheriting the
# document's. A property renders every language it has, side by side, and the root value is wrong for at least one of them:
# without this a screen reader says "Square" with Lithuanian phonetics and "Aikštė" with an English voice. An untagged
# literal makes no language claim at all, which HTML spells lang="" - the exact counterpart of RDF's absent tag - while a
# number is not prose and inherits, so it is read out in the reader's own language.

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')
doc_url="${END_USER_BASE_URL}${slug}/"

# the properties belong to the document's primary topic: a document describing nothing but itself renders its title and
# an empty body, so the values would never reach a dd

echo "<${doc_url}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${doc_url}> <http://purl.org/dc/terms/title> \"Language marking\" .
<${doc_url}> <http://xmlns.com/foaf/0.1/primaryTopic> <${doc_url}#this> .
<${doc_url}#this> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://example.org/test#Thing> .
<${doc_url}#this> <https://example.org/test#tagged> \"Aikštė\"@lt .
<${doc_url}#this> <https://example.org/test#tagged> \"Square\"@en .
<${doc_url}#this> <https://example.org/test#plain> \"Untagged value\" .
<${doc_url}#this> <https://example.org/test#typed> \"42\"^^<http://www.w3.org/2001/XMLSchema#integer> ." | \
  ldh put \
    -f "$OWNER_CERT_KEYSTORE" \
    -p "$OWNER_CERT_PWD" \
    -t "application/n-triples" \
    "$doc_url"

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# XHTML is the same rendering as text/html but well-formed, so the values can be queried with XPath rather than matched as
# text. Attribute order is a serialization detail - the build inlines entities through an XML round trip that alphabetizes
# literal-result-element attributes, while xsl:attribute instructions append in execution order - and nothing here depends
# on it
body=$(curl -k -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/xhtml+xml" \
  -H "Accept-Language: en" \
  "$doc_url")

count()
{
    echo "$body" | xmllint --xpath "count($1)" - 2> /dev/null || echo "0"
}

# the page is in English and both values are on it: each says which language it is in

[ "$(count "//*[local-name() = 'dd'][@property = 'https://example.org/test#tagged'][@lang = 'lt']")" = "1" ]
[ "$(count "//*[local-name() = 'dd'][@property = 'https://example.org/test#tagged'][@lang = 'en']")" = "1" ]

# an untagged literal claims no language rather than inheriting the document's

[ "$(count "//*[local-name() = 'dd'][@property = 'https://example.org/test#plain'][@lang = '']")" = "1" ]

# a number is not prose - it inherits, so it is read out in whatever language the reader is in

[ "$(count "//*[local-name() = 'dd'][@property = 'https://example.org/test#typed']")" = "1" ]
[ "$(count "//*[local-name() = 'dd'][@property = 'https://example.org/test#typed'][@lang]")" = "0" ]

# both languages of the property survive to the page - suppressing one is the defect this marking exists to make safe

[ "$(count "//*[local-name() = 'span'][@class = 'chip-inline']")" = "2" ]

ldh delete \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  "$doc_url" > /dev/null
