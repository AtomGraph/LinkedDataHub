#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# create restriction

namespace_doc="${END_USER_BASE_URL}ns"
namespace="${namespace_doc}#"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"
restriction="${namespace_doc}#Restriction"

add-restriction.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --uri "$restriction" \
  --label "Topic of document" \
  --on-property "http://xmlns.com/foaf/0.1/primaryTopic" \
  --all-values-from "http://www.w3.org/2000/01/rdf-schema#Resource" \
  "$ontology_doc"

# clear ontology from memory

clear-ontology.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace"

# check that the restriction is present in the ontology

curl -k -f -s -N \
  -H "Accept: application/n-triples" \
  "$namespace_doc" \
| grep "$restriction" > /dev/null