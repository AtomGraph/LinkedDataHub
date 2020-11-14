#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/model"

# create restriction

./create-restriction.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$ADMIN_BASE_URL" \
--uri "${END_USER_BASE_URL}ns/domain#Restriction" \
--label "Topic of document" \
--slug topic-of-document \
--on-property "http://xmlns.com/foaf/0.1/isPrimaryTopicOf" \
--all-values-from "http://xmlns.com/foaf/0.1/Document"

popd > /dev/null

# check that the restriction is present in the ontology

curl -k -f -s -N \
  -H "Accept: application/n-quads" \
  "${END_USER_BASE_URL}ns/domain" \
| grep -q "${END_USER_BASE_URL}ns/domain#Restriction"