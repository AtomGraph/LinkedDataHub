#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 6 ]; then
  echo "Usage:   $0 base parent cert_pem_file cert_password title slug" >&2
  echo "Example: $0" 'https://linkeddatahub.com/my-context/my-dataspace/ https://linkeddatahub.com/my-context/my-dataspace/ linkeddatahub.pem Password "My container" my-container' >&2
  exit 1
fi

base=$1
parent=$2
cert_pem_file=$3
cert_password=$4
class=${base}ns/default#Container

export title=$5
export slug=$6

envsubst < container.ttl | turtle --base=${base} | ./create-document.sh "$parent" "$cert_pem_file" "$cert_password" "application/n-triples" "$class"