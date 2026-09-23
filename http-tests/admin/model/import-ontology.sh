#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
clear_ontology

namespace_doc="${END_USER_BASE_URL}ns"
namespace="${namespace_doc}#"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"
import_uri="http://www.w3.org/2004/02/skos/core"

# create item

slug="test"

item=$(ldh create item \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --title "Test" \
  --slug "$slug" \
  --container "${ADMIN_BASE_URL}ontologies/")

# import the ontology: the vocabulary, the class constructors derived from it, and a foaf:primaryTopic
# naming what the document is about, all into the item document

ldh admin import ontology \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --source "$import_uri" \
  --graph "$item"

# check that the item graph DOES hold the vocabulary, using a query scoped to it via the SPARQL
# Protocol dataset specification. The vocabulary staying is what makes the import an import: the graph
# then declares the ontology, so resolving its URI finds this document and the annotations on it

result=$(curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <${import_uri}> a <http://www.w3.org/2002/07/owl#Ontology> }" \
  --data-urlencode "default-graph-uri=${item}" \
  "${ADMIN_BASE_URL}sparql")
count=$(echo "$result" | xmllint --xpath "count(//*[local-name() = 'result'])" -)
echo "DEBUG: vocabulary header in the item graph. Expected: 1  Got: $count"
if [ "$count" != "1" ]; then
  exit 1
fi

# check that constructors were derived into the item graph

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { ?class <http://spinrdf.org/spin#constructor> ?constructor }" \
  --data-urlencode "default-graph-uri=${item}" \
  "${ADMIN_BASE_URL}sparql" \
| grep '<result>' > /dev/null

# check that the item says what it is about

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <${item}> <http://xmlns.com/foaf/0.1/primaryTopic> <${import_uri}> }" \
  --data-urlencode "default-graph-uri=${item}" \
  "${ADMIN_BASE_URL}sparql" \
| grep '<result>' > /dev/null

# and that the document does NOT claim to be the ontology - the vocabulary stored alongside carries
# that, and a document conflated with its ontology is the shape this replaced

result=$(curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <${item}> a <http://www.w3.org/2002/07/owl#Ontology> }" \
  --data-urlencode "default-graph-uri=${item}" \
  "${ADMIN_BASE_URL}sparql")
count=$(echo "$result" | xmllint --xpath "count(//*[local-name() = 'result'])" -)
echo "DEBUG: document typed owl:Ontology. Expected: 0  Got: $count"
if [ "$count" != "0" ]; then
  exit 1
fi

# import the VOCABULARY into the application ontology, not the document holding it. Resolving that
# URI is what finds the imported document, because its graph declares the vocabulary an owl:Ontology

ldh admin add ontology-import \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --import "$import_uri" \
  "$ontology_doc"

# clear the namespace ontology from memory

ldh admin clear ontology \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace"

# check that the vocabulary is present in the ontology closure

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <${import_uri}> ?p ?o }" \
  "$namespace_doc" \
| grep '<literal xml:lang="en">SKOS Vocabulary</literal>' > /dev/null

# check that the derived constructors reached the closure too. This is the store-first precedence:
# SKOS is a bundled vocabulary, so under a mapping-first lookup the shipped file would answer and the
# constructors, which exist only in the imported document, would be invisible

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <http://www.w3.org/2004/02/skos/core#Concept> <http://spinrdf.org/spin#constructor> ?constructor }" \
  "$namespace_doc" \
| grep '<result>' > /dev/null
