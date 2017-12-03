#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 8 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title slug target query file" >&2
  echo "Example: $0" 'https://linkeddatahub.com/atomgraph/city-graph/ martynas.linkeddatahub.com Password "Copenhagen Places" 3c2623bb-5018-4630-8216-82b78ad0bcf7 https://linkeddatahub.com/atomgraph/city-graph/places/ https://linkeddatahub.com/atomgraph/city-graph/queries/a24f513d-e59f-4a3a-9995-0324cb8b4f47#this https://linkeddatahub.com/atomgraph/city-graph/uploads/646af756-a49f-40da-a25e-ea8d81f6d306' >&2
  exit 1
fi

urlencode()
{
  echo $(python -c 'import urllib, sys; print urllib.quote(  sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])' $1)
}

base=$1
cert_pem_file=$2
cert_password=$3
class=${base}ns#CSVImport
target=${base}imports/?forClass=$(urlencode "$class")

export title=$4
export slug=$5
export action=$6
export query=$7
export file=$8

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# convert Turtle to N-Triples using base URI, POST N-Triples to the server and print Location URL

envsubst < csv-import.ttl | turtle --base=${base} | curl -v -k -E ${cert_pem_file}:${cert_password} -d @- -H "Content-Type: application/n-triples" -H "Accept: text/turtle" ${target} -s -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'