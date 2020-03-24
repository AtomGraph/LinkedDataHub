#!/bin/bash

print_usage()
{
    printf "Appends RDF description.\n"
    printf "\n"
    printf "Usage:  echo -e \$rdf_body | %s options TARGET_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERTIFICATE      .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate (provided during signup)\n"
    printf "  -c, --class CLASS_URI                URI of the class that is the type of the document being created\n"
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
        -c|--class)
        class="$2"
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
    # echo '-f|--cert_pem_file not set'
    print_usage
    exit 1
fi

if [ -z "$cert_password" ] ; then
    # echo '-p|--cert-password not set'
    print_usage
    exit 1
fi

if [ -z "$class" ] ; then
    # echo '-c|--class not set'
    print_usage
    exit 1
fi

if [ -z "$content_type" ] ; then
    # echo '-t|--content-type not set'
    print_usage
    exit 1
fi

urlencode()
{
    python -c 'import urllib, sys; print urllib.quote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])' "$1"
}

if [ "$#" -ne 1 ]; then
    echo "Only one default argument is allowed"
    exit 1
fi

container="$1"
forClass=$(urlencode "$class")
target="${container}?forClass=${forClass}"

# POST RDF document from stdin to the server and print Location URL
cat - | curl -v -k -E "${cert_pem_file}":"${cert_password}" -d @- -H "Content-Type: ${content_type}" -H "Accept: text/turtle" "${target}" -s -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'