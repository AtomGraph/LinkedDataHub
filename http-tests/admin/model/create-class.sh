#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/model"

# create class

class="${END_USER_BASE_URL}ns/domain#NewClass"

./create-class.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$ADMIN_BASE_URL" \
--uri "$class" \
--label "New class" \
--slug new-class \
--sub-class-of "${END_USER_BASE_URL}ns/domain/default#Item"

popd > /dev/null

# check that the class is present in the ontology

curl -k -f -s -N \
  -H "Accept: application/n-triples" \
  "${END_USER_BASE_URL}ns/domain" \
| grep -q "$class"