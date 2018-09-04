#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 4 ]; then
  echo "Usage:   $0 cert_pem_file cert_password app_doc app_base" >&2
  echo "Example: $0" 'linkeddatahub.pem Password https://linkeddatahub.com/my/context/apps/end-user/my-dataspace https://linkeddatahub.com/my-dataspace/' >&2
  exit 1
fi

cert_pem_file=$1
cert_password=$2

export app_doc=$3
export app_base=$4

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# convert Turtle to N-Triples, POST N-Triples to the server

envsubst < install-dataset.ttl | turtle | curl -v -k -E $cert_pem_file:$cert_password -d @- -H "Content-Type: application/n-triples" -H "Accept: text/turtle" ${app_doc} -s -D -