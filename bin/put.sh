#!/usr/bin/env bash

print_usage()
{
    printf "Creates or updates an RDF document.\n"
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

url="$1"

if [ -n "$proxy" ]; then
    # rewrite target hostname to proxy hostname
    url_host=$(echo "$url" | cut -d '/' -f 1,2,3)
    proxy_host=$(echo "$proxy" | cut -d '/' -f 1,2,3)
    final_url="${url/$url_host/$proxy_host}"
else
    final_url="$url"
fi

# resolve RDF document from stdin against base URL and PUT to the server and print request URL
effective_url=$(cat - | turtle --base="$url" | curl -w '%{url_effective}' -f -v -k -E "$cert_pem_file":"$cert_password" -d @- -X PUT -H "Content-Type: ${content_type}" -H "Accept: text/turtle" -o /dev/null "$final_url") || exit $?

# If using proxy, rewrite the effective URL back to original hostname
if [ -n "$proxy" ]; then
    # Replace proxy host with original host in the effective URL
    rewritten_url="${effective_url/$proxy_host/$url_host}"
    echo "$rewritten_url"
else
    echo "$effective_url"
fi
