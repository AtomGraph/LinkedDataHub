#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 6 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title slug service" >&2
  echo "Example: $0" 'https://linkeddatahub.com/my-context/ linkeddatahub.pem Password "My dataspace" my-dataspace https://linkeddatahub.com/my-context/services/my-dataspace-admin' >&2
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3
class=${base}ns#AdminApplication

export title=$4
export slug=$5
export service=$6

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# set env values in the Turtle doc and sumbit it to the server

envsubst < admin-app.ttl | turtle --base=${base} | ../create-document.sh "${base}apps/admin/" "${cert_pem_file}" "${cert_password}" "text/turtle" "${class}"