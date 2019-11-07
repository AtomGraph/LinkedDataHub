#!/bin/bash

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
    *)    # unknown arguments
    args+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${args[@]}" # restore args

if [ -z "$cert_pem_file" ] ; then
    echo '-f|--cert_pem_file not set'
    exit 1
fi

if [ -z "$cert_password" ] ; then
    echo '-p|--cert-password not set'
    exit 1
fi

if [ -z "$base" ] ; then
    echo '-b|--base not set'
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Only one default argument is allowed"
    exit 1
fi

target="${base}model/ontologies/"
source="$1"
content_type="text/turtle"

turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="@prefix lsm:	<http://linkeddatahub.com/ns/sitemap/templates#> .\n"
turtle+="@prefix rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
turtle+="_:arg a lsm:Source .\n"
turtle+="_:arg ldt:paramName \"source\".\n"
turtle+="_:arg rdf:value <${source}>.\n"

# set env values in the Turtle doc and sumbit it to the server

# make Jena scripts available
export PATH="$PATH:$JENA_HOME/bin"

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | curl -v -k -E "$cert_pem_file":"$cert_password" -d @- -H "Content-Type: $content_type" -H "Accept: text/turtle" "$target" -s -D -