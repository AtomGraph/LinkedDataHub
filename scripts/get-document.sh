#!/bin/bash

print_usage()
{
    printf "Retrieves RDF description.\n"
    printf "\n"
    printf "Usage:  %s options TARGET_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERTIFICATE      .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate (provided during signup)\n"
    printf "  --accept MEDIA_TYPE                  Requested media type (e.g. text/turtle)\n"
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
        --accept)
        accept="$2"
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

if [ -z "$accept" ] ; then
    print_usage
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Only one default argument is allowed"
    exit 1
fi

target="$1"

# GET RDF document
curl -v -k -E "${cert_pem_file}":"${cert_password}" -H "Accept: ${accept}" "${target}" -s -I