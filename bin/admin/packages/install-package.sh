#!/usr/bin/env bash

print_usage()
{
    printf "Installs a LinkedDataHub package.\n"
    printf "\n"
    printf "Usage:  %s options\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -b, --base BASE_URL                  Base URL of the application\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "  --package PACKAGE_URI                URI of the package to install (e.g., https://packages.linkeddatahub.com/skos/#this)\n"
    printf "\n"
    printf "Example:\n"
    printf "  %s -b https://localhost:4443/ -f ssl/owner/cert.pem -p Password --package https://packages.linkeddatahub.com/skos/#this\n" "$0"
}

hash curl 2>/dev/null || { echo >&2 "curl not on \$PATH. Aborting."; exit 1; }

unknown=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -b|--base)
        base="$2"
        shift # past argument
        shift # past value
        ;;
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
        --package)
        package_uri="$2"
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

if [ -z "$base" ] ; then
    print_usage
    exit 1
fi
if [ -z "$cert_pem_file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$cert_password" ] ; then
    print_usage
    exit 1
fi
if [ -z "$package_uri" ] ; then
    print_usage
    exit 1
fi

# Convert base URL to admin base URL
admin_uri() {
    local uri="$1"
    echo "$uri" | sed 's|://|://admin.|'
}

admin_base=$(admin_uri "$base")
target_url="${admin_base}packages/install"

if [ -n "$proxy" ]; then
    admin_proxy=$(admin_uri "$proxy")
    # rewrite target hostname to proxy hostname
    url_host=$(echo "$target_url" | cut -d '/' -f 1,2,3)
    proxy_host=$(echo "$admin_proxy" | cut -d '/' -f 1,2,3)
    final_url="${target_url/$url_host/$proxy_host}"
else
    final_url="$target_url"
fi

# POST to packages/install endpoint
curl -k -w "%{http_code}\n" -E "${cert_pem_file}":"${cert_password}" \
    -X POST \
    -H "Accept: text/turtle" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "package-uri=${package_uri}" \
    "${final_url}"
