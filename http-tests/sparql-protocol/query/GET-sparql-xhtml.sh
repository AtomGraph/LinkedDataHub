#!/usr/bin/env bash
set -euo pipefail

# A SELECT result set asked for as a document renders as the application shell with a results table in it, the same way an
# RDF document does. What makes that worth pinning rather than assuming: the shell binds its content pane as="element()",
# so a result set no ldh:TabPanel rule matches does not degrade to an unstyled page - the whole response becomes a 500.
# That is how it regressed. The document-tabs work interposed ldh:TabPanel and ldh:DocumentBody between the shell and
# ldh:ContentBody, which has always had an srx:sparql rule, and widened neither of the two new ones beyond rdf:RDF.
#
# The query binds its own values, so what the table shows is a function of the query alone and the assertions hold against
# any dataset. XHTML rather than text/html because the same rendering is then well-formed and can be queried with XPath;
# text/html is asserted too, because that is the Accept a browser sends and the one the 500 was reported against.

purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

query='SELECT ?s ?label WHERE { VALUES (?s ?label) { (<https://example.org/results-table> "Results table") } }'

actual=$(curl -k -s -o /dev/null -w "%{http_code}" -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: text/html" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=$query")
expected="$STATUS_OK"
echo "DEBUG: Expected: $expected"
echo "DEBUG: Got: $actual"
[ "$actual" = "$expected" ]

body=$(curl -k -s -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/xhtml+xml" \
  -H "Accept-Language: en" \
  "${END_USER_BASE_URL}sparql" \
  --data-urlencode "query=$query")

count()
{
    echo "$body" | xmllint --xpath "count($1)" - 2> /dev/null || echo "0"
}

# the pane the shell failed to build: its absence is the regression, everything below it is what the pane is for

[ "$(count "//*[@id = 'tab-content']//*[contains(concat(' ', @class, ' '), ' ldh-pane ')]")" -ge "1" ]

# one results table, and a header cell per projected variable in the order the query projects them

[ "$(count "//*[local-name() = 'table'][contains(concat(' ', @class, ' '), ' ac-table ')]")" = "1" ]
[ "$(count "//*[local-name() = 'thead']/*[local-name() = 'tr']/*[local-name() = 'th'][1][normalize-space(.) = 's']")" = "1" ]
[ "$(count "//*[local-name() = 'thead']/*[local-name() = 'tr']/*[local-name() = 'th'][2][normalize-space(.) = 'label']")" = "1" ]

# a row per solution, its URI binding linked as a resource and its literal binding shown as text. The link is asserted by
# @title rather than @href because an off-origin URI is linked through the proxy, and which form that takes is not this
# test's subject - that the binding is a link at all, rather than the text of whatever label was found for it, is

[ "$(count "//*[local-name() = 'tbody']/*[local-name() = 'tr']")" = "1" ]
[ "$(count "//*[local-name() = 'tbody']/*[local-name() = 'tr']/*[local-name() = 'td'][1]/*[local-name() = 'a'][@title = 'https://example.org/results-table']")" = "1" ]
[ "$(count "//*[local-name() = 'tbody']/*[local-name() = 'tr']/*[local-name() = 'td'][2][normalize-space(.) = 'Results table']")" = "1" ]
