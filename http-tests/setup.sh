#!/bin/bash

if [ "$#" -ne 6 ]; then
  echo "Usage:   $0" '$env_file $alias $owner_cert $owner_cert_pwd $owner_public_key $validity' >&2
  echo "Example: $0 .env martynas martynas.localhost.p12 Password martynas.localhost.pem 3650" >&2
  exit 1
fi

env_file="$1"

alias="$2"
owner_cert="$3"
owner_cert_pwd="$4"
owner_public_key="$5"
validity="$6"

secretary_keystore="ssl/secretary/keystore.p12"
secretary_keystore_pwd="LinkedDataHub"
secretary_cert="ssl/secretary/cert.pem"
secretary_cert_pwd="LinkedDataHub"
secretary_cert_validity=36500

mkdir -p ssl/secretary

declare -A env

# read file line by line and populate the array. Field separator is "="
while IFS='=' read -r k v; do
    if [ ! -z $k ] ; then env["$k"]="$v"; fi
done < "$env_file"

for x in "${!env[@]}"; do printf "[%s]=%s\n" "$x" "${env[$x]}" ; done

if [ "${env['PROTOCOL']}" = "https" ]; then
    if [ "${env['HTTPS_PORT']}" = 443 ]; then
        export base_uri="${env['PROTOCOL']}://${env['HOST']}${env['ABS_PATH']}"
    else
        export base_uri="${env['PROTOCOL']}://${env['HOST']}:${env['HTTPS_PORT']}${env['ABS_PATH']}"
    fi
else
    if [ "${env['HTTP_PORT']}" = 80 ]; then
        export base_uri="${env['PROTOCOL']}://${env['HOST']}${env['ABS_PATH']}"
    else
        export base_uri="${env['PROTOCOL']}://${env['HOST']}:${env['HTTP_PORT']}${env['ABS_PATH']}"
    fi
fi

printf "\n ### Base URI: %s\n" "$base_uri"

# create owner certificate

owner_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
owner_uri="${base_uri}admin/acl/agents/${owner_uuid}/#this"

printf "\n### Owner's WebID URI: %s\n" "$owner_uri"

owner_cert_dname="CN=${env['OWNER_GIVEN_NAME']} ${env['OWNER_FAMILY_NAME']}, OU=${env['OWNER_ORG_UNIT']}, O=${env['OWNER_ORGANIZATION']}, L=${env['OWNER_LOCALITY']}, ST=${env['OWNER_STATE_OR_PROVINCE']}, C=${env['OWNER_COUNTRY_NAME']}"

keytool \
    -alias "$alias" \
    -genkeypair \
    -keyalg RSA \
    -storetype PKCS12 \
    -keystore "$owner_cert" \
    -storepass "$owner_cert_pwd" \
    -keypass "$owner_cert_pwd" \
    -dname "$owner_cert_dname" \
    -ext "SAN=uri:${owner_uri}" \
    -validity "$validity"

# convert owner's certificate to PEM

openssl pkcs12 -in "$owner_cert" -passin pass:"$owner_cert_pwd" -nokeys -out "$owner_public_key" # only export the public key!

# create secratary's certificate

secretary_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
secretary_uri="${base_uri}admin/acl/agents/${secretary_uuid}/#this"

printf "\n### Secretary's WebID URI: %s\n" "$secretary_uri"

secretary_dname="CN=LDH, OU=LDH, O=AtomGraph, L=Copenhagen, ST=Denmark, C=DK"

keytool \
    -genkeypair \
    -alias "ldh-secretary" \
    -keyalg RSA \
    -storetype PKCS12 \
    -keystore "$secretary_keystore" \
    -storepass "$secretary_keystore_pwd" \
    -keypass "$secretary_cert_pwd" \
    -dname "$secretary_dname" \
    -ext "SAN=uri:${secretary_uri}" \
    -validity "$secretary_cert_validity"

printf "\n### Secretary WebID certificate's DName attributes: %s\n" "$secretary_dname"

# convert secretary's certificate to PEM

openssl \
    pkcs12 \
    -in "$secretary_keystore" \
    -passin pass:"$secretary_keystore_pwd" \
    -out "$secretary_cert" \
    -passout pass:"$secretary_cert_pwd"

# ===
# openssl pkcs12 -in "$owner_cert" -out ./http-tests/owner.p12.pem -passin pass:"$owner_cert_pwd" -passout pass:"$owner_cert_pwd" # re-generate the owner PEM cert - seems to differ with different openssl versions?

# openssl pkcs12 -in ./certs/secretary.p12 -out ./http-tests/secretary.p12.pem -passin pass:"$secretary_cert_pwd" -passout pass:"$secretary_cert_pwd