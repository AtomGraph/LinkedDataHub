#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
clear_ontology

# add a class to the app's namespace ontology

namespace_doc="${END_USER_BASE_URL}ns"
namespace="${namespace_doc}#"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"
class="${namespace}ClassThree"

ldh admin add class \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --uri "$class" \
  --label "Class Three" \
  "$ontology_doc"

# clear ontology from memory so the new class is loaded on next request

ldh admin clear ontology \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace"

# GET <ns> with no ?query= should return the raw namespace ontology graph (asserted
# triples only, no RDFS materialization) rather than run a SPARQL query

response=$(curl -k -f -s \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$namespace_doc")

# here-strings rather than pipes: N-Triples come back unordered, so the class can be on any line of the graph, and
# grep -q hitting an early one closes the pipe with the rest unwritten - under `set -o pipefail` the SIGPIPE'd echo
# then fails a test whose response was exactly right

grep -q "$class" <<< "$response"
! grep -q "http://www.w3.org/2000/01/rdf-schema#Resource" <<< "$response"
