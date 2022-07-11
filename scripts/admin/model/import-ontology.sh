#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2017 Martynas Jusevicius <martynas@atomgraph.com> 
# SPDX-FileCopyrightText: 2017 LinkedDataHub
#
# SPDX-License-Identifier: Apache-2.0

# LinkedDataHub

print_usage()
{
    printf "Imports external ontology into the model.\n"
    printf "\n"
    printf "Usage:  %s options\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --source SOURCE_URI                  URI of the imported ontology\n"
}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH. Need to set \$JENA_HOME. Aborting."; exit 1; }
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
        -b|--base)
        base="$2"
        shift # past argument
        shift # past value
        ;;
        --proxy)
        proxy="$2"
        shift # past argument
        shift # past value
        ;;
        --source)
        source="$2"
        shift # past argument
        shift # past value
        ;;
        --graph)
        graph="$2"
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
    print_usage
    exit 1
fi
if [ -z "$cert_password" ] ; then
    print_usage
    exit 1
fi
if [ -z "$base" ] ; then
    print_usage
    exit 1
fi
if [ -z "$source" ] ; then
    print_usage
    exit 1
fi
if [ -z "$graph" ] ; then
    print_usage
    exit 1
fi

target="${base}transform"

if [ -n "$proxy" ]; then
    # rewrite target hostname to proxy hostname
    target_host=$(echo "$target" | cut -d '/' -f 1,2,3)
    proxy_host=$(echo "$proxy" | cut -d '/' -f 1,2,3)
    target="${target/$target_host/$proxy_host}"
fi

content_type="text/turtle"

turtle+="_:arg <http://purl.org/dc/terms/source> <${source}> .\n"
turtle+="_:arg <http://www.w3.org/ns/sparql-service-description#name> <${graph}> .\n"
turtle+="_:arg <http://spinrdf.org/spin#query> <${base}queries/construct-constructors/#this> .\n"

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | curl -s -k -E "$cert_pem_file":"$cert_password" -d @- -H "Content-Type: $content_type" -H "Accept: text/turtle" "$target" -s -D -
