#!/bin/bash

if [ "$#" -ne 7 ]; then
  echo "Usage:   $0 cert_pem_file cert_password password title query_file file target" >&2
  echo "Example: $0" 'https://linkeddatahub.com/atomgraph/city-graph/ martynas.linkeddatahub.pem Password "Copenhagen Places" queries/constructPlaces.rq "files/Copenhagen geo data - Places.csv" https://linkeddatahub.com/atomgraph/city-graph/places/' >&2
  exit 1
fi

uuid()
{
  echo $(od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}')
}

base=$1
cert_pem_file=$2
cert_password=$3
title=$4
query_doc_slug=$(uuid)
query_file=$5
file_doc_slug=$(uuid)
file_slug=$(uuid)
file=$6
import_slug=$(uuid)
action=$7

query_doc=$(./create-query.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$query_doc_slug" "$query_file")

file=$(./create-file.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$file_doc_slug" "$file_slug" "$file" "text/csv")

import=$(./create-csv-import.sh "$base" "$cert_pem_file" "$cert_password" "$title" "$import_slug" "$action" "$query_doc#this" "$file")