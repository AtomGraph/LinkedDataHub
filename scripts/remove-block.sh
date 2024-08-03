#!/usr/bin/env bash

print_usage()
{
    printf "Removes content block from document.\n"
    printf "\n"
    printf "Usage:  %s options TARGET_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --block BLOCK_URI                    URI of the content block (optional)\n"
}

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
        --proxy)
        proxy="$2"
        shift # past argument
        shift # past value
        ;;
        --block)
        block="$2"
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
if [ -z "$block" ] ; then
    print_usage
    exit 1
fi

target="$1"
this="$target"

if [ -n "$proxy" ]; then
    # rewrite target hostname to proxy hostname
    target_host=$(echo "$target" | cut -d '/' -f 1,2,3)
    proxy_host=$(echo "$proxy" | cut -d '/' -f 1,2,3)
    target="${target/$target_host/$proxy_host}"
fi

if [ -n "$block" ] ; then
    block="<${block}>"
else
    block="?block"
fi

curl -X PATCH \
    -v -f -k \
    -E "$cert_pem_file":"$cert_password" \
    -H "Content-Type: application/sparql-update" \
    "$target" \
     --data-binary @- <<EOF
DELETE
{
    <${this}> ?seq ${block} .
    ${block} ?p ?o .
}
WHERE
{
    <${this}> ?seq ${block} .
    OPTIONAL
    {
        ${block} ?p ?o
    }
}

EOF