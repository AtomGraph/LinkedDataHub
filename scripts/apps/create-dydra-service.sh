#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 8 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title slug repository service_user service_password" >&2
  echo "Example: $0" 'https://linkeddatahub.com/my-context/ linkeddatahub.pem Password "My context" my-context http://dydra.com/my-context/end-user ServiceUser ServicePassword' >&2
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3
class=${base}ns#DydraService

export title=$4
export slug=$5
export repository=$6
export service_user=$7
export service_password=$8

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# set env values in the Turtle doc and sumbit it to the server

envsubst < dydra-service.ttl | ../create-document.sh "${base}" "${base}services/" "${cert_pem_file}" "${cert_password}" "${class}"