#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2017 Martynas Jusevicius <martynas@atomgraph.com> 
# SPDX-FileCopyrightText: 2017 LinkedDataHub
#
# SPDX-License-Identifier: Apache-2.0

# LinkedDataHub

print_usage()
{
    printf "Creates an RDF document.\n"
    printf "\n"
    printf "Usage:  cat data.ttl | %s options TARGET_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
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
        --proxy)
        proxy="$2"
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

if [ -n "$proxy" ]; then
    # rewrite target hostname to proxy hostname
    target_host=$(echo "$target" | cut -d '/' -f 1,2,3)
    proxy_host=$(echo "$proxy" | cut -d '/' -f 1,2,3)
    target="${target/$target_host/$proxy_host}"
fi

# POST RDF document from stdin to the server and print Location URL
cat - | curl -v -k -E "$cert_pem_file":"$cert_password" -d @- -H "Content-Type: ${content_type}" -H "Accept: text/turtle" "$target" -v -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'
