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

item=$(create-item.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --title "Test" \
  --slug "$slug" \
  --container "${ADMIN_BASE_URL}ontologies/")

# import the ontology into the item document and derive class constructors from it

import-ontology.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --source "$import_uri" \
  --graph "$item"

# check that the item graph holds the raw ontology, using a query scoped to it via the SPARQL Protocol dataset specification

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <${import_uri}> ?p ?o }" \
  --data-urlencode "default-graph-uri=${item}" \
  "${ADMIN_BASE_URL}sparql" \
| grep '<literal xml:lang="en">SKOS Vocabulary</literal>' > /dev/null

# check that constructors were derived into the item graph

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { ?class <http://spinrdf.org/spin#constructor> ?constructor }" \
  --data-urlencode "default-graph-uri=${item}" \
  "${ADMIN_BASE_URL}sparql" \
| grep '<result>' > /dev/null

# add ontology import

add-ontology-import.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --import "$import_uri" \
  "$ontology_doc"

# clear the namespace ontology from memory

clear-ontology.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace"

# check that the imported ontology is present in the ontology model TO-DO: replace with an ASK query when #118 is fixed

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { <${import_uri}> ?p ?o }" \
  "$namespace_doc" \
| grep '<literal xml:lang="en">SKOS Vocabulary</literal>' > /dev/null

# check that the derived constructors made it into the ontology model, tied to the imported ontology via rdfs:isDefinedBy

curl -k -f -s \
  -G \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H 'Accept: application/sparql-results+xml' \
  --data-urlencode "query=SELECT * { ?class <http://spinrdf.org/spin#constructor> ?constructor . ?class <http://www.w3.org/2000/01/rdf-schema#isDefinedBy> <${import_uri}> }" \
  "$namespace_doc" \
| grep '<result>' > /dev/null
