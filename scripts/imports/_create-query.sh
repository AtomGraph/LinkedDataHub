#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 6 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title slug query_file" >&2
  echo "Example: $0" 'https://linkeddatahub.com/atomgraph/city-graph/ martynas.linkeddatahub.pem Password "Copenhagen Places" a24f513d-e59f-4a3a-9995-0324cb8b4f47 queries/constructPlaces.rq' >&2
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3
class=${base}ns#Construct
container=${base}queries/

export title=$4
export slug=$5
export query=$(<$6)

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# convert Turtle to N-Triples using base URI and create a document

envsubst < construct.ttl | turtle --base=${base} | ../create-document.sh "${container}" "$cert_pem_file" "$cert_password" "application/n-triples" "$class"