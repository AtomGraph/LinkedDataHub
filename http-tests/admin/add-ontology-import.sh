#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin"

# create template

./add-ontology-import.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
--import "https://schema.org" \
"${ADMIN_BASE_URL}model/ontologies/domain/"

popd > /dev/null

# check that the template is present in the ontology

curl -k -f -s -N \
  -H "Accept: application/n-quads" \
  "${END_USER_BASE_URL}ns/domain" \
| grep -q "<${END_USER_BASE_URL}ns/domain#> <http://www.w3.org/2002/07/owl#imports> <https://schema.org>"