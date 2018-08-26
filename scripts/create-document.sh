#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 5 ]; then
  echo "Usage:   cat doc.ttl | $0 container cert_pem_file cert_password content_type class" >&2
  echo "Example: cat doc.ttl | $0" 'https://linkeddatahub.com/my-context/my-dataspace/ linkeddatahub.pem Password application/n-triples "https://linkeddatahub.com/my-context/my-dataspace/ns#Class"' >&2
  exit 1
fi

urlencode()
{
  echo $(python -c 'import urllib, sys; print urllib.quote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])' $1)
}

container=$1
cert_pem_file=$2
cert_password=$3
content_type=$4
class=$5

target=${container}?forClass=$(urlencode "$class")

# POST RDF document from stdin to the server and print Location URL

cat - | curl -v -k -E "${cert_pem_file}":"${cert_password}" -d @- -H "Content-Type: ${content_type}" -H "Accept: text/turtle" "${target}" -s -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'