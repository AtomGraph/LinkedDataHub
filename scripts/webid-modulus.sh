#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage:   $0 cert_p12_file cert_password" >&2
  echo "Example: $0 martynas.localhost.p12 Password" >&2
  exit 1
fi

cert="$1"
password="$2"

modulus_string=$(openssl pkcs12 -in "$cert" -nodes -passin pass:"$password" 2>/dev/null | openssl x509 -noout -modulus)
modulus="${modulus_string##*Modulus=}" # cut Modulus= text
echo "${modulus}" | tr '[:upper:]' '[:lower:]' # lowercase