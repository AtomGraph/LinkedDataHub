#!/bin/bash

[ -z "$SCRIPT_ROOT" ] && echo "Need to set SCRIPT_ROOT" && exit 1;

if [ "$#" -ne 3 ]; then
  echo "Usage:   $0 $base $cert_pem_file $cert_password" >&2
  echo "Example: $0" 'https://localhost:4443/demo/skos/ ../../../../../certs/martynas.stage.localhost.pem Password' >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

base=$1
cert_pem_file=$(realpath -s $2)
cert_password=$3

pushd . && cd $SCRIPT_ROOT/admin/model

./create-restriction.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#TopicOfConceptItem" \
--label "Topic of concept item" \
--slug topic-of-concept-item \
--on-property "http://xmlns.com/foaf/0.1/isPrimaryTopicOf" \
--all-values-from "${base}ns/domain#ConceptItem"

./create-restriction.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#TopicOfConceptSchemeItem" \
--label "Topic of concept scheme item" \
--slug topic-of-concept-scheme-item \
--on-property "http://xmlns.com/foaf/0.1/isPrimaryTopicOf" \
--all-values-from "${base}ns/domain#ConceptSchemeItem"

./create-restriction.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#ItemOfConceptContainer" \
--label "Item of concept container" \
--slug item-of-concept-container \
--on-property "http://rdfs.org/sioc/ns#has_container" \
--has-value "${base}concepts/"

./create-restriction.sh \
-b "${base}admin/" \
-f "$cert_pem_file" \
-p "$cert_password" \
--uri "${base}ns/domain#ItemOfConceptSchemeContainer" \
--label "Item of concept scheme container" \
--slug item-of-concept-scheme-container \
--on-property "http://rdfs.org/sioc/ns#has_container" \
--has-value "${base}concept-schemes/"

popd