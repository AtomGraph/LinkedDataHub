#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# create a constraint making the sioc:content property mandatory

namespace_doc="${END_USER_BASE_URL}ns"
namespace="${namespace_doc}#"
ontology_doc="${ADMIN_BASE_URL}ontologies/namespace/"
constraint="${namespace_doc}#NewConstraint"

add-property-constraint.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --uri "$constraint" \
  --label "New constraint" \
  --property "http://rdfs.org/sioc/ns#content" \
  "$ontology_doc"

# create a class with the constraint

add-class.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --uri "${namespace_doc}#ConstrainedClass" \
  --label "Constrained class" \
  --constraint "$constraint" \
  --sub-class-of "https://www.w3.org/ns/ldt/document-hierarchy#Item" \
  "$ontology_doc"

# clear ontology from memory

clear-ontology.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace"

# check that the constraint is present in the ontology

curl -k -f -s -N \
  -H "Accept: application/n-triples" \
  "$namespace_doc" \
| grep "$constraint" > /dev/null

# check that creating an instance of the class without sioc:content returns 422 Unprocessable Entity due to missing sioc:content

turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="_:item a <${namespace_doc}#ConstrainedClass> .\n"
turtle+="_:item dct:title \"Failure\" .\n"
turtle+="_:item sioc:has_container <${END_USER_BASE_URL}> .\n"

response=$(echo -e "$turtle" \
| turtle --base="$END_USER_BASE_URL" \
| put.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --content-type "text/turtle" \
  "$END_USER_BASE_URL" \
2>&1) # redirect output from stderr to stdout

echo "$response" \
| grep "HTTP/1.1 422" > /dev/null
