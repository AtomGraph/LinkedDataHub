#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 3 ]; then
  echo "Usage:   $0 cert_pem_file cert_password ontology_doc" >&2
  echo "Example: $0" 'martynas.linkeddatahub.pem Password https://linkeddatahub.com/atomgraph/city-graph/admin/sitemap/ontologies/templates' >&2
  exit 1
fi

cert_pem_file=$1
cert_password=$2
ontology_doc=$3

curl -v -k -E ${cert_pem_file}:${cert_password} "${ontology_doc}?clear=" -H "Accept: text/turtle"