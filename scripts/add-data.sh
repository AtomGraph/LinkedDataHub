#!/bin/bash

print_usage()
{
    printf "Appends RDF description to the dataset.\n"
    printf "\n"
    printf "Usage:  cat data.ttl | %s options TARGET_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "\n"
    printf "  -t, --content-type MEDIA_TYPE        Media type of the RDF body (e.g. text/turtle)\n"
}

hash curl 2>/dev/null || { echo >&2 "curl not on \$PATH. Aborting."; exit 1; }

unknown=()
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
        -t|--content-type)
        content_type="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown option
        unknown+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done
set -- "${unknown[@]}" # restore args

if [ -z "$cert_pem_file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$cert_password" ] ; then
    print_usage
    exit 1
fi
if [ -z "$content_type" ] ; then
    print_usage
    exit 1
fi
if [ "$#" -ne 1 ]; then
    print_usage
    exit 1
fi

target="$1"

# POST RDF document from stdin to the server
cat - | curl -v -k -E "${cert_pem_file}":"${cert_password}" -d @- -H "Content-Type: ${content_type}" -H "Accept: text/turtle" "${target}" -v -D - | tr -d '\r'