#!/bin/bash

hash curl 2>/dev/null || { echo >&2 "curl not on \$PATH. Aborting."; exit 1; }

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
    *)    # unknown arguments
    args+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${args[@]}" # restore args

if [ -z "$cert_pem_file" ] ; then
    echo '-f|--cert_pem_file not set'
    exit 1
fi

if [ -z "$cert_password" ] ; then
    echo '-p|--cert-password not set'
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Only one default argument is allowed"
    exit 1
fi

ontology_doc="$1"

curl -v -k -E "$cert_pem_file":"$cert_password" "${ontology_doc}?clear=" -H "Accept: text/turtle"