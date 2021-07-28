#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/model"

# create class

class="${ADMIN_BASE_URL}model/ontologies/domain/#NewClass"

./create-class.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$ADMIN_BASE_URL" \
--uri "$class" \
--label "New class" \
--slug new-class \
--sub-class-of "${ADMIN_BASE_URL}model/ontologies/default/#Item"

popd > /dev/null

# check that the class is present in the ontology

curl -k -f -s -N \
  -H "Accept: application/n-triples" \
  "${ADMIN_BASE_URL}model/ontologies/domain/" \
| grep -q "$class"