#!/bin/bash

if [ "$#" -ne 12 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title slug app_base admin_repository admin_service_user admin_service_password end_user_repository end_user_service_user end_user_service_password" >&2
  echo "Example: $0" 'https://linkeddatahub.com/ ../../certs/martynas.linkeddatahub.pem Password AtomGraph atomgraph https://linkeddatahub.com/atomgraph/ http://atomgraph.dydra.com/atomgraph/ldh-context-admin-prod AdminServiceUser AdminServicePassword http://atomgraph.dydra.com/atomgraph/ldh-context-prod EndUserServiceUser EndUserServicePassword' >&2
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3
title=$4
slug=$5
app_base=$6
admin_repository=$7
admin_service_user=$8
admin_service_password=$9
end_user_repository=${10}
end_user_service_user=${11}
end_user_service_password=${12}

admin_service_doc=$(./create-dydra-service.sh "$base" "$cert_pem_file" "$cert_password" "$title admin" "$slug-admin" "$admin_repository" "$admin_service_user" "$admin_service_password")

service_doc=$(./create-dydra-service.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$slug" "$end_user_repository" "$end_user_service_user" "$end_user_service_password")

admin_app_doc=$(./create-admin-app.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$slug" "$admin_service_doc#this")

./create-context-app.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$slug" "$app_base" "$admin_app_doc#this" "$service_doc#this"