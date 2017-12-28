#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 7 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password label slug path query" >&2
  echo "Example: $0" 'https://linkeddatahub.com/atomgraph/city-graph/admin/ martynas.linkeddatahub.pem Password "Copenhagen Places" a24f513d-e59f-4a3a-9995-0324cb8b4f47 "/places/" https://linkeddatahub.com/atomgraph/city-graph/admin/queries/copenhagen-places#this' >&2
  exit 1
fi

urlencode()
{
  echo $(python -c 'import urllib, sys; print urllib.quote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])' $1)
}

base=$1
cert_pem_file=$2
cert_password=$3
class=${base}ns#Template
target=${base}sitemap/templates/?forClass=$(urlencode "$class")

export label=$4
export slug=$5
export path=$6
export query=$7

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# convert Turtle to N-Triples using base URI, POST N-Triples to the server and print Location URL

envsubst < template.ttl | turtle --base=${base} | curl -v -k -E ${cert_pem_file}:${cert_password} -d @- -H "Content-Type: application/n-triples" -H "Accept: text/turtle" ${target} -s -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'