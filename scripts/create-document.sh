#!/bin/bash

# ./create-document.sh -f shit -t text/turtle -c Class http://target -p XXX

UNKNOWN=()
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
    UNKNOWN+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${UNKNOWN[@]}" # restore unknown parameters

if [ -z "$cert_pem_file" ] ; then
    echo '-f|--cert_pem_file not set'
    exit 1
fi

if [ -z "$cert_password" ] ; then
    echo '-p|--cert-password not set'
    exit 1
fi

if [ -z "$class" ] ; then
    echo '-c|--class not set'
    exit 1
fi

if [ -z "$content_type" ] ; then
    echo '-t|--content-type not set'
    exit 1
fi

urlencode()
{
  echo $(python -c 'import urllib, sys; print urllib.quote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])' $1)
}

echo "class        = ${class}"
echo "content_type = ${content_type}"

if [ "$#" -ne 1 ]; then
    echo "Only one default argument is allowed"
    exit 1
fi

container=$1
echo "container    = ${container}"

target=${container}?forClass=$(urlencode "$class")
echo "target       = ${target}"

# POST RDF document from stdin to the server and print Location URL

cat - | curl -v -k -E "${cert_pem_file}":"${cert_password}" -d @- -H "Content-Type: ${content_type}" -H "Accept: text/turtle" "${target}" -s -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'