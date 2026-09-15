#!/usr/bin/env bash
set -euo pipefail

# The graph a document serves as RDF and the graph its markup asserts are meant to be the same graph: what the page shows
# is what the page says. Three things used to break that and each is pinned here - a value's rendered text stood in for its
# literal, so a formatted date or a language pill became the value; @typeof without a subject minted a blank node, so a
# block's type described a node in no graph; and the document's own description was rendered as chrome, which asserts
# nothing, so its title, timestamps, parent and block membership were in no representation of the page at all.
#
# XHTML rather than text/html because the same rendering is then well-formed and can be queried with XPath. Attribute
# order is a serialization detail and nothing here depends on it.

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')
doc_url="${END_USER_BASE_URL}${slug}/"

echo "<${doc_url}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/ldt/document-hierarchy#Item> .
<${doc_url}> <http://purl.org/dc/terms/title> \"Graph in markup\" .
<${doc_url}> <http://xmlns.com/foaf/0.1/primaryTopic> <${doc_url}#this> .
<${doc_url}#this> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://example.org/test#Thing> .
<${doc_url}#this> <https://example.org/test#date> \"2026-09-12\"^^<http://www.w3.org/2001/XMLSchema#date> .
<${doc_url}#this> <https://example.org/test#count> \"42\"^^<http://www.w3.org/2001/XMLSchema#integer> .
<${doc_url}#this> <https://example.org/test#empty> \"\" .
<${doc_url}#this> <https://example.org/test#ref> <https://example.org/target> ." | \
  ldh put \
    -f "$OWNER_CERT_KEYSTORE" \
    -p "$OWNER_CERT_PWD" \
    -t "application/n-triples" \
    "$doc_url"

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

body=$(curl -k -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/xhtml+xml" \
  -H "Accept-Language: en" \
  "$doc_url")

count()
{
    echo "$body" | xmllint --xpath "count($1)" - 2> /dev/null || echo "0"
}

# a date is shown formatted and asserted as its lexical form: @content is the only attribute that lets the two differ

[ "$(count "//*[@property = 'https://example.org/test#date'][@content = '2026-09-12']")" -ge "1" ]
[ "$(count "//*[@property = 'https://example.org/test#date'][@datatype = 'http://www.w3.org/2001/XMLSchema#date']")" -ge "1" ]

# a number keeps its datatype, which is also what stops it inheriting the page's language

[ "$(count "//*[@property = 'https://example.org/test#count'][@datatype = 'http://www.w3.org/2001/XMLSchema#integer'][@content = '42']")" -ge "1" ]

# an empty literal is still a statement: RDF/XML gives it no text node, and the row used to disappear with it

[ "$(count "//*[@property = 'https://example.org/test#empty'][@content = '']")" -ge "1" ]

# a URI object is asserted as a resource, never as the text of whatever label was rendered for it

[ "$(count "//*[@property = 'https://example.org/test#ref'][@resource = 'https://example.org/target']")" -ge "1" ]
[ "$(count "//*[@property = 'https://example.org/test#ref'][@content]")" = "0" ]

# the document describes itself: what the chrome shows and what it omits are both asserted

[ "$(count "//*[@property = 'http://purl.org/dc/terms/title'][@content = 'Graph in markup']")" -ge "1" ]
[ "$(count "//*[@property = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'][@resource = 'https://www.w3.org/ns/ldt/document-hierarchy#Item']")" -ge "1" ]
[ "$(count "//*[@property = 'http://xmlns.com/foaf/0.1/primaryTopic'][@resource = '${doc_url}#this']")" -ge "1" ]

# the RDFa default subject is the document, not the request URI - otherwise every head-level assertion moves to a
# different subject the moment a query string is present

[ "$(count "//*[local-name() = 'html'][@about = '${doc_url}']")" = "1" ]

# @typeof without a subject mints a blank node, so a type asserted that way describes a node in no graph. Every element
# that types something has to name what it is typing, or inherit a name from an ancestor that does

[ "$(count "//*[@typeof][not(@about)][not(@resource)][not(ancestor::*[@about])]")" = "0" ]

ldh delete \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  "$doc_url" > /dev/null
