#!/usr/bin/env bash
set -e

# check that uuidgen command is available
hash uuidgen 2>/dev/null || { echo >&2 "uuidgen not on \$PATH. Aborting."; exit 1; }

if [ "$#" -ne 5 ]; then
    echo "Usage:   $0" '$env_file $out_folder $owner_cert_pwd $secretary_cert_pwd $validity' >&2
    echo "Example: $0 .env ssl Password Password 3650" >&2
    exit 1
fi

env_file="$1"
out_folder="$2"

printf "### Output folder: %s\n" "$out_folder"

proxy_host="nginx"

server_cert="${out_folder}/server/server.crt"
server_public_key="${out_folder}/server/server.key"

owner_alias="owner"
owner_keystore="${out_folder}/owner/keystore.p12"
owner_cert_pwd="$3"
owner_cert="${out_folder}/owner/cert.pem"
owner_public_key="${out_folder}/owner/public.pem"

secretary_alias="secretary"
secretary_keystore="${out_folder}/secretary/keystore.p12"
secretary_cert="${out_folder}/secretary/cert.pem"
secretary_cert_pwd="$4"
secretary_cert_dname="CN=LDH, OU=LDH, O=AtomGraph, L=Copenhagen, ST=Denmark, C=DK"

validity="$5"

# append secretary cert password to the env_file
echo "" >> "$env_file"
echo "SECRETARY_CERT_PASSWORD=${secretary_cert_pwd}" >> "$env_file"

function envProp {
  local expectedKey=$1
  while IFS='=' read -r k v; do
      if [ -n "$k" ] && [ "$k" == "$expectedKey" ] ; then
        echo "$v";
        break;
      fi
  done < "$env_file"
}

if [ -z "$(envProp "PROTOCOL")" ]; then
    echo "Configuration is incomplete: PROTOCOL is missing"
    exit 1
fi
if [ -z "$(envProp "HTTPS_PORT")" ]; then
    echo "Configuration is incomplete: HTTPS_PORT is missing"
    exit 1
fi
if [ -z "$(envProp "HTTP_PORT")" ]; then
    echo "Configuration is incomplete: HTTP_PORT is missing"
    exit 1
fi
if [ -z "$(envProp "HOST")" ]; then
    echo "Configuration is incomplete: HOST is missing"
    exit 1
fi
if [ -z "$(envProp "ABS_PATH")" ]; then
    echo "Configuration is incomplete: ABS_PATH is missing"
    exit 1
fi

if [ "$(envProp "PROTOCOL")" = "https" ]; then
    if [ "$(envProp "HTTPS_PORT")" = 443 ]; then
        base_uri="$(envProp "PROTOCOL")://$(envProp "HOST")$(envProp "ABS_PATH")"
    else
        base_uri="$(envProp "PROTOCOL")://$(envProp "HOST"):$(envProp "HTTPS_PORT")$(envProp "ABS_PATH")"
    fi
else
    if [ "$(envProp "HTTP_PORT")" = 80 ]; then
        base_uri="$(envProp "PROTOCOL")://$(envProp "HOST")$(envProp "ABS_PATH")"
    else
        base_uri="$(envProp "PROTOCOL")://$(envProp "HOST"):$(envProp "HTTP_PORT")$(envProp "ABS_PATH")"
    fi
fi

printf "\n### Base URI: %s\n" "$base_uri"

### SERVER CERT ###

mkdir -p "$out_folder"/server

# crude check if the host is an IP address
if [[ "$(envProp "HOST")" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    if [ -n "$proxy_host" ]; then
        san="subjectAltName=IP:$(envProp "HOST"),DNS:${proxy_host}" # IP address - special case for localhost
    else
        san="subjectAltName=IP:$(envProp "HOST")" # IP address
    fi
else
    if [ -n "$proxy_host" ]; then
        san="subjectAltName=DNS:$(envProp "HOST"),DNS:${proxy_host}" # hostname - special case for localhost
    else
        san="subjectAltName=DNS:$(envProp "HOST")" # hostname
    fi
fi

# openssl <= 1.1.1
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout "$server_public_key" \
  -out "$server_cert" \
  -subj "/CN=$(envProp "HOST")/OU=LinkedDataHub/O=AtomGraph/L=Copenhagen/C=DK" \
  -extensions san \
  -config <(echo '[req]'; echo 'distinguished_name=req';
            echo '[san]'; echo "$san")

# openssl >= 1.1.1
#openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
#  -keyout "$server_public_key" \
#  -out "$server_cert" \
#  -subj "/CN=$(envProp "HOST")/OU=LinkedDataHub/O=AtomGraph/L=Copenhagen/C=DK" \
#  -addext "$san"

### OWNER CERT ###

if [ -z "$(envProp "OWNER_GIVEN_NAME")" ]; then
    echo "Configuration is incomplete: OWNER_GIVEN_NAME is missing"
    exit 1
fi
if [ -z "$(envProp "OWNER_FAMILY_NAME")" ]; then
    echo "Configuration is incomplete: OWNER_FAMILY_NAME is missing"
    exit 1
fi
if [ -z "$(envProp "OWNER_ORG_UNIT")" ]; then
    echo "Configuration is incomplete: OWNER_ORG_UNIT is missing"
    exit 1
fi
if [ -z "$(envProp "OWNER_ORGANIZATION")" ]; then
    echo "Configuration is incomplete: OWNER_ORGANIZATION is missing"
    exit 1
fi
if [ -z "$(envProp "OWNER_LOCALITY")" ]; then
    echo "Configuration is incomplete: OWNER_LOCALITY is missing"
    exit 1
fi
if [ -z "$(envProp "OWNER_STATE_OR_PROVINCE")" ]; then
    echo "Configuration is incomplete: OWNER_STATE_OR_PROVINCE is missing"
    exit 1
fi
if [ -z "$(envProp "OWNER_COUNTRY_NAME")" ]; then
    echo "Configuration is incomplete: OWNER_COUNTRY_NAME is missing"
    exit 1
fi

owner_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
owner_uri="${base_uri}admin/acl/agents/${owner_uuid}/#this"

printf "\n### Owner's WebID URI: %s\n" "$owner_uri"

owner_cert_dname="CN=$(envProp "OWNER_GIVEN_NAME") $(envProp "OWNER_FAMILY_NAME"), OU=$(envProp "OWNER_ORG_UNIT"), O=$(envProp "OWNER_ORGANIZATION"), L=$(envProp "OWNER_LOCALITY"), ST=$(envProp "OWNER_STATE_OR_PROVINCE"), C=$(envProp "OWNER_COUNTRY_NAME")"
printf "\n### Owner WebID certificate's DName attributes: %s\n" "$owner_cert_dname"

mkdir -p "$out_folder"/owner

keytool \
    -genkeypair \
    -alias "$owner_alias" \
    -keyalg RSA \
    -storetype PKCS12 \
    -keystore "$owner_keystore" \
    -storepass "$owner_cert_pwd" \
    -keypass "$owner_cert_pwd" \
    -dname "$owner_cert_dname" \
    -ext "SAN=uri:${owner_uri}" \
    -validity "$validity"

# convert owner's certificate to PEM

openssl \
    pkcs12 \
    -in "$owner_keystore" \
    -passin pass:"$owner_cert_pwd" \
    -out "$owner_cert" \
    -passout pass:"$owner_cert_pwd"

# convert owner's public key to PEM

openssl \
    pkcs12 \
    -in "$owner_keystore" \
    -passin pass:"$owner_cert_pwd" \
    -nokeys \
    -out "$owner_public_key"

### SECRETARY CERT ###

mkdir -p "$out_folder"/secretary

secretary_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
secretary_uri="${base_uri}admin/acl/agents/${secretary_uuid}/#this"

printf "\n### Secretary's WebID URI: %s\n" "$secretary_uri"

printf "\n### Secretary WebID certificate's DName attributes: %s\n" "$secretary_cert_dname"

keytool \
    -genkeypair \
    -alias "$secretary_alias" \
    -keyalg RSA \
    -storetype PKCS12 \
    -keystore "$secretary_keystore" \
    -storepass "$secretary_cert_pwd" \
    -keypass "$secretary_cert_pwd" \
    -dname "$secretary_cert_dname" \
    -ext "SAN=uri:${secretary_uri}" \
    -validity "$validity"

# convert secretary's certificate to PEM

openssl \
    pkcs12 \
    -in "$secretary_keystore" \
    -passin pass:"$secretary_cert_pwd" \
    -out "$secretary_cert" \
    -passout pass:"$secretary_cert_pwd"