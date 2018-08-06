#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

if [ "$#" -ne 9 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title slug app_base public admin_app service" >&2
  echo "Example: $0" 'https://linkeddatahub.com/my-context/ linkeddatahub.pem Password "My dataspace" my-dataspace https://linkeddatahub.com/my-context/my-dataspace/ https://linkeddatahub.com/my-context/apps/admin/my-dataspace https://linkeddatahub.com/my-context/services/my-dataspace true' >&2
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3
class=${base}ns#EndUserApplication

export title=$4
export slug=$5
export app_base=$6
if [ "$7" = "false" ]; then 
    export public=false
else
    export public=true
fi;
export admin_app=$8
export service=$9

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# set env values in the N-Triples doc and sumbit it to the server

envsubst < end-user-app.ttl | turtle --base=${base} | ../create-document.sh "${base}apps/end-user/" "${cert_pem_file}" "${cert_password}" "text/turtle" "${class}"