#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 8 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title slug app_base admin_app service" >&2
  echo "Example: $0" 'https://linkeddatahub.com/ linkeddatahub.pem Password "My context" my-context https://linkeddatahub.com/my-context/ https://linkeddatahub.com/apps/admin/my-context https://linkeddatahub.com/services/my-context' >&2
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3
class=${base}ns#Context

export title=$4
export slug=$5
export app_base=$6
export admin_app=$7
export service=$8

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# convert Turtle to N-Triples using base URI, POST N-Triples to the server and print Location URL

envsubst < context.ttl | turtle --base=${base} | ../create-document.sh "${base}" "${base}apps/end-user/" "${cert_pem_file}" "${cert_password}" "${class}"