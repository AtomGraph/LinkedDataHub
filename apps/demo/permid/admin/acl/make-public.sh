#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Usage:   $0 $base $cert_pem_file $cert_password" >&2
  echo "Example: $0" 'https://localhost/atomgraph/app/ ../../../certs/martynas.localhost.pem Password' >&2
  echo "Note: special characters such as $ need to be escaped in passwords!" >&2
  exit 1
fi

base=$1
cert_pem_file=$2
cert_password=$3

{ echo "BASE <${base}admin/>" ; cat ./make-public.ru ; } | curl -X PATCH -d @- -v -k -E ${cert_pem_file}:${cert_password} "${base}admin/graphs/a86ce4fa-0197-4118-878e-32ea2d695878" -H "Content-Type: application/sparql-update"