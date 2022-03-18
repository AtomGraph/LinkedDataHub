#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin"

ontology_doc="${ADMIN_BASE_URL}model/ontologies/namespace/"

# add ontology import

./add-ontology-import.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --import "https://schema.org" \
  "$ontology_doc"

# clear ontology from memory

./clear-ontology.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  "$ontology_doc"

popd > /dev/null

# check that the import is present in the ontology

curl -k -f -s -N \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}ns" \
| grep "<${END_USER_BASE_URL}ns#> <http://www.w3.org/2002/07/owl#imports> <https://schema.org>" > /dev/null