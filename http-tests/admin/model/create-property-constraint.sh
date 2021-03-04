#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/model"

# create a constraint making the sioc:content property mandatory

constraint="${END_USER_BASE_URL}ns/domain#NewConstraint"

./create-property-constraint.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$ADMIN_BASE_URL" \
--uri "$constraint" \
--label "New constraint" \
--slug new-constraint \
--property "http://rdfs.org/sioc/ns#content"

# create a class with the constraint

./create-class.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$ADMIN_BASE_URL" \
--uri "${END_USER_BASE_URL}ns/domain#ConstrainedClass" \
--label "Constrained class" \
--slug constrained-class \
--constraint "$constraint" \
--sub-class-of "${END_USER_BASE_URL}ns/domain/default#Item"

popd > /dev/null

# check that the constraint is present in the ontology

curl -k -f -s -N \
  -H "Accept: application/n-quads" \
  "${END_USER_BASE_URL}ns/domain" \
| grep -q "${END_USER_BASE_URL}ns/domain#NewConstraint"

# clear ontology from memory

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin"

./clear-ontology.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
"${ADMIN_BASE_URL}model/ontologies/domain/"

popd > /dev/null

# check that creating an instance of the class without sioc:content returns Bad Request due to missing sioc:content

pushd . > /dev/null && cd "$SCRIPT_ROOT"

turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="_:item a <${END_USER_BASE_URL}ns/domain#ConstrainedClass> .\n"
turtle+="_:item dct:title \"Failure\" .\n"
turtle+="_:item sioc:has_container <${END_USER_BASE_URL}> .\n"

response=$(echo -e "$turtle" \
| turtle --base="$END_USER_BASE_URL" \
| ./create-document.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
--class "${END_USER_BASE_URL}ns/domain#ConstrainedClass" \
--content-type "text/turtle" \
"${END_USER_BASE_URL}" \
2>&1) # redirect output from stderr to stdout

echo "$response" \
| grep -q "HTTP/1.1 400"

popd > /dev/null