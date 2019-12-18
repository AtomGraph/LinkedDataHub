#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage:   $0 cert_pem_file cert_password" >&2
  echo "Example: $0 martynas.localhost.pem Password" >&2
  exit 1
fi

cert="$1"
password="$2"

openssl x509 -in "$cert" -text -noout -passin pass:"$password" \
  -certopt no_subject,no_header,no_version,no_serial,no_signame,no_validity,no_issuer,no_pubkey,no_sigdump,no_aux \
  | awk '/X509v3 Subject Alternative Name/ {getline; print}' | xargs | tail -c +5