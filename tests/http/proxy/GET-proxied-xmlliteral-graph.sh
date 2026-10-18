#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# add agent to the readers group to be able to read documents

ldh admin add agent \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/readers/"

# Regression: a document holding an XML literal whose content is a graph - an rdf:RDF element, as an assistant turn
# stores a CONSTRUCT result - is well-formed RDF/XML, and Jena writes it as rdf:parseType="Literal" markup. Jena's
# default RDF/XML parser (RDFXML-SAX) rejects it ("Inconsistent parserMode:TOP", apache/jena#4334), and the proxy,
# which forwards the client's Accept: application/rdf+xml and parses what comes back, answered 502 for the whole
# document. The platform reads RDF/XML with the StAX parser instead.

item=$(ldh create item \
  -c "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --container "$END_USER_BASE_URL" \
  --title "XML literal holding a graph" \
  --slug "xmlliteral-graph")

echo "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

INSERT {
  <${item}#result> <http://example.org/graph> \"\"\"<wa:result xmlns:wa=\"https://w3id.org/atomgraph/web-algebra\"><rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"><rdf:Description rdf:about=\"http://example.org/inner\"></rdf:Description></rdf:RDF></wa:result>\"\"\"^^rdf:XMLLiteral .
  <${item}#result> <http://example.org/after> \"after\" .
} WHERE {}" | \
  ldh patch \
    -c "$OWNER_CERT_KEYSTORE" \
    -p "$OWNER_CERT_PWD" \
    "$item"

# the document itself still serves the literal as markup - which is what made it unparseable

direct=$(curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/rdf+xml" \
  "$item")

echo "$direct" | grep -q 'rdf:parseType="Literal"' || { echo "DEBUG: the document no longer serves the literal as markup:"; echo "$direct"; exit 1; }

# proxied, as Saxon-JS asks for it

body=$(mktemp)
trap 'rm -f "$body"' EXIT
status=$(curl -k -s -G -o "$body" -w "%{http_code}" \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/rdf+xml" \
  --data-urlencode "uri=${item}" \
  "$ADMIN_BASE_URL")

echo "DEBUG: proxied status ${status}"
[ "$status" = "200" ] || { cat "$body"; exit 1; }

# and the triple after the literal survived the round trip

grep -q '>after<' "$body" || { echo "DEBUG: proxied body:"; cat "$body"; exit 1; }
