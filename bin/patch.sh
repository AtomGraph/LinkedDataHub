#!/usr/bin/env bash

print_usage()
{
    printf "Patches an RDF document using SPARQL update.\n"
    printf "\n"
    printf "Usage:  cat update.rq | %s options TARGET_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH.  Aborting."; exit 1; }
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
if [ "$#" -ne 1 ]; then
    print_usage
    exit 1
fi

url="$1"

if [ -n "$proxy" ]; then
    # rewrite target hostname to proxy hostname
    url_host=$(echo "$url" | cut -d '/' -f 1,2,3)
    proxy_host=$(echo "$proxy" | cut -d '/' -f 1,2,3)
    final_url="${url/$url_host/$proxy_host}"
else
    final_url="$url"
fi

# resolve SPARQL update from stdin against base URL and PATCH it to the server
# uparse currently does not support --base: https://github.com/apache/jena/issues/3296
cat - | curl -v -k -E "$cert_pem_file":"$cert_password" --data-binary @- -H "Content-Type: application/sparql-update" -X PATCH -o /dev/null "$final_url"
