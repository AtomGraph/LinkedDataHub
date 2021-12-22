#!/bin/bash
set -euxo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/model"

# create a constraint making the sioc:content property mandatory

ontology_doc="${ADMIN_BASE_URL}model/ontologies/namespace/"
constraint="${ontology_doc}#NewConstraint"

./create-property-constraint.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$ADMIN_BASE_URL" \
--uri "$constraint" \
--label "New constraint" \
--slug new-constraint \
--property "http://rdfs.org/sioc/ns#content" \
"$ontology_doc"

# create a class with the constraint

./create-class.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
-b "$ADMIN_BASE_URL" \
--uri "${ontology_doc}#ConstrainedClass" \
--label "Constrained class" \
--slug constrained-class \
--constraint "$constraint" \
--sub-class-of "https://w3id.org/atomgraph/linkeddatahub/default#Item" \
"$ontology_doc"

popd > /dev/null

# check that the constraint is present in the ontology

curl -k -f -s -N \
  -H "Accept: application/n-triples" \
  "${ontology_doc}" \
| grep -q "${ontology_doc}#NewConstraint"

# clear ontology from memory

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin"

./clear-ontology.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
"${ontology_doc}"

popd > /dev/null

# check that creating an instance of the class without sioc:content returns Bad Request due to missing sioc:content

pushd . > /dev/null && cd "$SCRIPT_ROOT"

turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="_:item a <${ontology_doc}#ConstrainedClass> .\n"
turtle+="_:item dct:title \"Failure\" .\n"
turtle+="_:item sioc:has_container <${END_USER_BASE_URL}> .\n"

response=$(echo -e "$turtle" \
| turtle --base="$END_USER_BASE_URL" \
| ./create-document.sh \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
--content-type "text/turtle" \
"${END_USER_BASE_URL}" \
2>&1) # redirect output from stderr to stdout

echo "$response" \
| grep -q "HTTP/1.1 400"

popd > /dev/null