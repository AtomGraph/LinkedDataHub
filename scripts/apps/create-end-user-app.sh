#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 8 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title slug app_base admin_app service" >&2
  echo "Example: $0" 'https://linkeddatahub.com/my-context/ linkeddatahub.pem Password "My dataspace" my-dataspace https://linkeddatahub.com/my-context/my-dataspace/ https://linkeddatahub.com/my-context/apps/admin/my-dataspace https://linkeddatahub.com/my-context/services/my-dataspace' >&2
  exit 1
fi

urlencode()
{
  echo $(python -c 'import urllib, sys; print urllib.quote(  sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])' $1)
}

base=$1
cert_pem_file=$2
cert_password=$3
class=${base}ns#EndUserApplication
target=${base}apps/end-user/?forClass=$(urlencode "$class")

export title=$4
export slug=$5
export app_base=$6
export admin_app=$7
export service=$8

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# convert Turtle to N-Triples using base URI, POST N-Triples to the server and print Location URL

envsubst < end-user-app.ttl | turtle --base=${base} | curl -v -k -E $cert_pem_file:$cert_password -d @- -H "Content-Type: application/n-triples" -H "Accept: text/turtle" ${target} -s -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'