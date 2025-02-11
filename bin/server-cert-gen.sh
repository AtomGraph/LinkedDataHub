#!/usr/bin/env bash
set -e

if [ "$#" -ne 3 ]; then
    echo "Usage:   $0" '$env_file $proxy_host $out_folder' >&2
    echo "Example: $0 .env nginx ssl" >&2
    exit 1
fi

env_file="$1"
proxy_host="$2"
out_folder="$3"
server_cert="${out_folder}/server/server.crt"
server_public_key="${out_folder}/server/server.key"

function envProp {
  local expectedKey=$1
  while IFS='=' read -r k v; do
      if [ -n "$k" ] && [ "$k" == "$expectedKey" ] ; then
        echo "$v";
        break;
      fi
  done < "$env_file"
}

printf "### Output folder: %s\n" "$out_folder"

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
