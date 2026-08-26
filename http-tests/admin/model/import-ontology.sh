#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"

namespace_doc="${END_USER_BASE_URL}ns"
namespace="${namespace_doc}#"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"
import_uri="http://www.w3.org/2004/02/skos/core"

# create item

slug="test"

item=$(ldh create-item \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --title "Test" \
  --slug "$slug" \
  --container "${ADMIN_BASE_URL}ontologies/")

# import the ontology: derive class constructors into the item document; the vocabulary itself only
# passes through a scratch document and is not persisted

ldh admin ontologies import-ontology \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --source "$import_uri" \
  --graph "$item"

# check that the item graph does NOT hold the raw vocabulary, using a query scoped to it via the
# SPARQL Protocol dataset specification

result=$(curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <${import_uri}> ?p ?o }" \
  --data-urlencode "default-graph-uri=${item}" \
  "${ADMIN_BASE_URL}sparql")
count=$(echo "$result" | xmllint --xpath "count(//*[local-name() = 'result'])" -)
if [ "$count" != "0" ]; then
  echo "DEBUG: Expected 0 raw vocabulary triples in the item graph, got: $count"
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

# check that the item carries the annotation-ontology header importing the source vocabulary

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <${item}> a <http://www.w3.org/2002/07/owl#Ontology> ; <http://www.w3.org/2002/07/owl#imports> <${import_uri}> }" \
  --data-urlencode "default-graph-uri=${item}" \
  "${ADMIN_BASE_URL}sparql" \
| grep '<result>' > /dev/null

# make the annotation document part of the application ontology (the vocabulary rides in via the
# document's own owl:imports)

ldh admin add-ontology-import \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --import "$item" \
  "$ontology_doc"

# clear the namespace ontology from memory

ldh admin clear-ontology \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace"

# check that the vocabulary is present in the ontology closure (resolved through the graph
# repository - SKOS is a bundled vocabulary - via the annotation document's owl:imports)

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <${import_uri}> ?p ?o }" \
  "$namespace_doc" \
| grep '<literal xml:lang="en">SKOS Vocabulary</literal>' > /dev/null

# check that the derived constructors reached the closure too - impossible under the old model for
# bundled vocabularies, where the shipped file shadowed the local copy that held the constructors

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <http://www.w3.org/2004/02/skos/core#Concept> <http://spinrdf.org/spin#constructor> ?constructor }" \
  "$namespace_doc" \
| grep '<result>' > /dev/null
