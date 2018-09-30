#!/bin/bash

[ -z "$SCRIPT_ROOT" ] && echo "Need to set SCRIPT_ROOT" && exit 1;

if [ "$#" -ne 2 ]; then
  echo "Usage:   $0 $cert_pem_file $cert_password" >&2
  echo "Example: $0" '../../../certs/martynas.linkeddatahub.pem Password' >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

cert_pem_file=$(realpath -s $1)
cert_password=$2

./install.sh https://linkeddatahub.com/demo/city-graph/ "$cert_pem_file" "$cert_password"