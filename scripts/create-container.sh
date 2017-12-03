#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 6 ]; then
  echo "Usage:   $0 base parent cert_pem_file cert_password title slug" >&2
  echo "Example: $0" 'https://linkeddatahub.com/atomgraph/city-graph/ https://linkeddatahub.com/atomgraph/city-graph/ ../certs/martynas.linkeddatahub.pem Password "Copenhagen" copenhagen' >&2
  exit 1
fi

urlencode()
{
  echo $(python -c 'import urllib, sys; print urllib.quote(  sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])' $1)
}

base=$1
parent=$2
cert_pem_file=$3
cert_password=$4
class=${base}default#Container
target=${parent}?forClass=$(urlencode "$class")

export title=$5
export slug=$6

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# convert Turtle to N-Triples using base URI, POST N-Triples to the server and print Location URL

envsubst < container.ttl | turtle --base=${base} | curl -v -k -E ${cert_pem_file}:${cert_password} -d @- -H "Content-Type: application/n-triples" -H "Accept: text/turtle" ${target} -s -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'