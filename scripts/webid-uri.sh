#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage:   $0" '$public_key_pem_file' >&2
    echo "Example: $0 martynas.localhost.pem" >&2
    exit 1
fi

key_pem="$1"

openssl x509 -in "$key_pem" -text -noout \
  -certopt no_subject,no_header,no_version,no_serial,no_signame,no_validity,no_issuer,no_pubkey,no_sigdump,no_aux \
  | awk '/X509v3 Subject Alternative Name/ {getline; print}' | xargs | tail -c +5