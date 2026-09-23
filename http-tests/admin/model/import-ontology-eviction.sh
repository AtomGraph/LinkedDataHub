#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"
reset_packages
clear_ontology

# An imported vocabulary answers for its own URI only while the document holding it exists. The graph
# is cached under that URI, the cache outlives the document, and eviction used to drop only the keys
# derived from the ontology being cleared - so a deleted document kept being served, and one test's
# import kept answering for the next. This pins the deletion end of it.
#
# Counted relative to where it starts, not against zero. Every document declaring the vocabulary an
# owl:Ontology contributes to the closure - that is the feature - so an absolute count would be
# asserting that no other such document exists, which is true of a fresh instance and not what this
# test is about. The baseline is also the first thing printed, so a failure before it locates itself.

namespace_doc="${END_USER_BASE_URL}ns"
namespace="${namespace_doc}#"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"
import_uri="http://www.w3.org/2004/02/skos/core"

constructors() {
  curl -k -f -s \
    -G \
    -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
    -H 'Accept: application/sparql-results+xml' \
    --data-urlencode "query=SELECT * { <${import_uri}#Concept> <http://spinrdf.org/spin#constructor> ?constructor }" \
    "$namespace_doc" \
  | xmllint --xpath "count(//*[local-name() = 'result'])" -
}

before=$(constructors)
echo "DEBUG: [baseline] constructors for skos:Concept before the import: $before"

item=$(ldh create item \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --title "Evicted" \
  --slug "evicted" \
  --container "${ADMIN_BASE_URL}ontologies/")

ldh admin import ontology \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --source "$import_uri" \
  --graph "$item"

# the application ontology imports the VOCABULARY, and resolving it reaches the document above
ldh admin add ontology-import \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --import "$import_uri" \
  "$ontology_doc"

ldh admin clear ontology \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace"

imported=$(constructors)
echo "DEBUG: [imported] constructors for skos:Concept. Expected: >$before  Got: $imported"
if [ "$imported" -le "$before" ]; then
  echo "DEBUG: [imported] the derived constructors never reached the closure" >&2
  exit 1
fi

# delete the document that supplied them, then clear without naming an ontology

ldh delete \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  "$item"

clear_ontology

final=$(constructors)
echo "DEBUG: [deleted] constructors for skos:Concept. Expected: $before  Got: $final"
if [ "$final" != "$before" ]; then
  echo "DEBUG: [deleted] a graph cached under <${import_uri}> outlived the document it came from" >&2
  exit 1
fi
