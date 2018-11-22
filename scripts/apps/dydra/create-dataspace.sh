#!/bin/bash
set -E
trap onexit ERR

function onexit() {
    local exit_status=${1:-$?}
    echo Exiting $0 with $exit_status
    exit $exit_status
}

if [ "$#" -ne 13 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title slug app_base public admin_repository admin_service_user admin_service_password end_user_repository end_user_service_user end_user_service_password" >&2
  echo "Example: $0" 'https://linkeddatahub.com/my-context/ linkeddatahub.pem Password "My dataspace" my-dataspace https://linkeddatahub.com/my-context/my-dataspace/ true http://dydra.com/my-dataspace/admin AdminServiceUser AdminServicePassword http://dydra.com/my-dataspace/end-user EndUserServiceUser EndUserServicePassword' >&2
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3
title=$4
slug=$5
app_base=$6
public=$7
admin_repository=$8
admin_service_user=$9
admin_service_password=${10}
end_user_repository=${11}
end_user_service_user=${12}
end_user_service_password=${13}

admin_service_doc=$(./create-service.sh "$base" "$cert_pem_file" "$cert_password" "$title admin" "$slug-admin" "$admin_repository" "$admin_service_user" "$admin_service_password")

service_doc=$(./create-service.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$slug" "$end_user_repository" "$end_user_service_user" "$end_user_service_password")

pushd . && cd ..

admin_app_doc=$(./create-admin-app.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$slug" "$admin_service_doc#this")

./create-end-user-app.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$slug" "$app_base" "$public" "$admin_app_doc#this" "$service_doc#this"

popd