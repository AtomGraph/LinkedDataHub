#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage:   $0" '$public_key_pem_file' >&2
    echo "Example: $0 martynas.localhost.pem" >&2
    exit 1
fi

key_pem="$1"

modulus_string=$(cat "$key_pem" | openssl x509 -noout -modulus)
modulus="${modulus_string##*Modulus=}" # cut Modulus= text
echo "${modulus}" | tr '[:upper:]' '[:lower:]' # lowercase