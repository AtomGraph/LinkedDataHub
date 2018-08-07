#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 8 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title slug action query file" >&2
  echo "Example: $0" 'https://linkeddatahub.com/atomgraph/city-graph/ martynas.linkeddatahub.com Password "Copenhagen Places" 3c2623bb-5018-4630-8216-82b78ad0bcf7 https://linkeddatahub.com/atomgraph/city-graph/places/ https://linkeddatahub.com/atomgraph/city-graph/queries/a24f513d-e59f-4a3a-9995-0324cb8b4f47#this https://linkeddatahub.com/atomgraph/city-graph/uploads/646af756-a49f-40da-a25e-ea8d81f6d306' >&2
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3
class=${base}ns#CSVImport
container=${base}imports/

export title=$4
export slug=$5
export action=$6
export query=$7
export file=$8

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# convert Turtle to N-Triples using base URI and create a document

envsubst < csv-import.ttl | turtle --base=${base} | ../create-document.sh "${container}" "$cert_pem_file" "$cert_password" "application/n-triples" "$class"