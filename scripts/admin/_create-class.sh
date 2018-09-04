#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 6 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password label slug constructor" >&2
  echo "Example: $0" 'https://linkeddatahub.com/atomgraph/city-graph/admin/ martynas.linkeddatahub.pem Password "Place" a24f513d-e59f-4a3a-9995-0324cb8b4f47 https://linkeddatahub.com/atomgraph/city-graph/admin/model/queries/constructor#this' >&2
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3
class=${base}ns#Class
container=${base}model/classes/

export label=$4
export slug=$5
export constructor=$6

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# convert Turtle to N-Triples using base URI, POST N-Triples to the server and print Location URL

envsubst < class.ttl | turtle --base=${base} | ../create-document.sh "${container}" "$cert_pem_file" "$cert_password" "application/n-triples" "$class"