#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/sitemap"

# create template

./create-template.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$ADMIN_BASE_URL" \
--uri "${END_USER_BASE_URL}ns/templates#NewTemplate" \
--label "New template" \
--slug new-template \
--extends "${END_USER_BASE_URL}ns/templates#Document" \
--match "/" \
--is-defined-by "${END_USER_BASE_URL}ns/templates#"

popd > /dev/null

# check that the template is present in the ontology

curl -k -f -s -N \
  -H "Accept: application/n-quads" \
  "${END_USER_BASE_URL}ns/templates" \
| grep -q "${END_USER_BASE_URL}ns/templates#NewTemplate"

# clear ontology from memory

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin"

./clear-ontology.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
"${ADMIN_BASE_URL}sitemap/ontologies/templates/"

popd > /dev/null

# check that the new template matches /

curl -k -f -I -N \
  -E "$OWNER_CERT_FILE":"$OWNER_CERT_PWD" \
  -H "Accept: application/n-quads" \
  "${END_USER_BASE_URL}" \
| grep "Link: <${END_USER_BASE_URL}ns/templates#NewTemplate>; rel=https://www.w3.org/ns/ldt#template"