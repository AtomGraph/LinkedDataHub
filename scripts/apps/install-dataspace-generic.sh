#!/bin/bash

if [ "$#" -ne 14 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title slug app_base admin_endpoint admin_graph_store admin_service_user admin_service_password end_user_endpoint end_user_graph_store end_user_service_user end_user_service_password" >&2
  echo "Example: $0" 'https://linkeddatahub.com/my-context/ linkeddatahub.pem Password "My dataspace" my-dataspace https://linkeddatahub.com/my-context/my-dataspace/ http://localhost:3030/admin/sparql AdminServiceUser AdminServicePassword http://localhost:3030/end-user/sparql EndUserServiceUser EndUserServicePassword' >&2
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3
title=$4
slug=$5
app_base=$6
admin_endpoint=$7
admin_graph_store=$8
admin_service_user=$9
admin_service_password=${10}
end_user_endpoint=${11}
end_user_graph_store=${12}
end_user_service_user=${13}
end_user_service_password=${14}

admin_service_doc=$(./create-generic-service.sh "$base" "$cert_pem_file" "$cert_password" "$title admin" "$slug-admin" "$admin_endpoint" "$admin_graph_store" "$admin_service_user" "$admin_service_password")

service_doc=$(./create-generic-service.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$slug" "$end_user_endpoint" "$end_user_graph_store" "$end_user_service_user" "$end_user_service_password")

admin_app_doc=$(./create-admin-app.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$slug" "$admin_service_doc#this")

end_user_app_doc=$(./create-end-user-app.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$slug" "$app_base" "$admin_app_doc#this" "$service_doc#this")

./install-dataset.sh $cert_pem_file $cert_password $admin_app_doc "${app_base}admin/"

./install-dataset.sh $cert_pem_file $cert_password $end_user_app_doc $app_base