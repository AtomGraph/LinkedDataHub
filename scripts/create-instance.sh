#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 5 ]; then
  echo "Usage:   cat instance.ttl | $0 base parent cert_pem_file cert_password class" >&2
  echo "Example: cat instance.ttl | $0" 'https://linkeddatahub.com/my-context/my-dataspace/ https://linkeddatahub.com/my-context/my-dataspace/ linkeddatahub.pem Password "My container" my-container' >&2
  exit 1
fi

urlencode()
{
  echo $(python -c 'import urllib, sys; print urllib.quote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])' $1)
}

base=$1
parent=$2
cert_pem_file=$3
cert_password=$4
class=$5

target=${parent}?forClass=$(urlencode "$class")

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# convert Turtle to N-Triples using base URI, POST N-Triples to the server and print Location URL

cat - | turtle --base=${base} | curl -v -k -E ${cert_pem_file}:${cert_password} -d @- -H "Content-Type: application/n-triples" -H "Accept: text/turtle" "${target}" -s -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'
