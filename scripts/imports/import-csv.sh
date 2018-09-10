#!/bin/bash

args=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -f|--cert-pem-file)
    cert_pem_file="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--cert-password)
    cert_password="$2"
    shift # past argument
    shift # past value
    ;;
    -b|--base)
    base="$2"
    shift # past argument
    shift # past value
    ;;
    --title)
    title="$2"
    shift # past argument
    shift # past value
    ;;
    --description)
    description="$2"
    shift # past argument
    shift # past value
    ;;
    --slug)
    slug="$2"
    shift # past argument
    shift # past value
    ;;
    --action)
    action="$2"
    shift # past argument
    shift # past value
    ;;
    --query-file)
    query_file="$2"
    shift # past argument
    shift # past value
    ;;
    --query-doc-slug)
    query_doc_slug="$2"
    shift # past argument
    shift # past value
    ;;
    --file)
    file="$2"
    shift # past argument
    shift # past value
    ;;
    --file-slug)
    file_slug="$2"
    shift # past argument
    shift # past value
    ;;
    --file-doc-slug)
    file_doc_slug="$2"
    shift # past argument
    shift # past value
    ;;
    --delimiter)
    delimiter="$2"
    shift # past argument
    shift # past value
    ;;
    --import-slug)
    import_slug="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown arguments
    args+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${args[@]}" # restore args

query_doc=$(./create-query.sh -b "$base" -f "$cert_pem_file" -p "$cert_password" --title "$title" --slug --slug "$query_doc_slug" --query-file "$query_file")

file=$(./create-file.sh -b "$base" -f "$cert_pem_file" -p "$cert_password" --title "$title" --slug "$file_doc_slug" --file-slug "$file_slug" --file "$file" --file-content-type "text/csv")

import=$(./create-csv-import.sh -b "$base" -f "$cert_pem_file" -p "$cert_password" --title "$title" --slug "$import_slug" --action "$action" --query "$query_doc#this" --file "$file" --delimiter ",")