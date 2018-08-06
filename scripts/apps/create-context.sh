#!/bin/bash

if [ "$#" -ne 15 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title slug app_base public admin_endpoint admin_graph_store admin_service_user admin_service_password end_user_endpoint end_user_graph_store end_user_service_user end_user_service_password" >&2
  echo "Example: $0" 'https://linkeddatahub.com/ linkeddatahub.pem Password "My context" my-context https://linkeddatahub.com/my-context/ true http://localhost:3030/admin/sparql http://localhost:3030/admin/data AdminServiceUser AdminServicePassword http://localhost:3030/end-user/sparql http://localhost:3030/end-user/data EndUserServiceUser EndUserServicePassword'
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3
title=$4
slug=$5
app_base=$6
public=$7
admin_endpoint=$8
admin_graph_store=$9
admin_service_user=${10}
admin_service_password=${11}
end_user_endpoint=${12}
end_user_graph_store=${13}
end_user_service_user=${14}
end_user_service_password=${15}

admin_service_doc=$(./create-service.sh "$base" "$cert_pem_file" "$cert_password" "$title admin" "$slug-admin" "$admin_endpoint" "$admin_graph_store" "$admin_service_user" "$admin_service_password")

service_doc=$(./create-service.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$slug" "$end_user_endpoint" "$end_user_graph_store" "$end_user_service_user" "$end_user_service_password")

admin_app_doc=$(./create-admin-app.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$slug" "$admin_service_doc#this")

end_user_app_doc=$(./create-context-app.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$slug" "$app_base" "$public" "$admin_app_doc#this" "$service_doc#this")