#!/bin/bash

print_usage()
{
    printf "Imports external ontology into the model.\n"
    printf "\n"
    printf "Usage:  %s options ONTOLOGY_DOC_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
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
        --source)
        source="$2"
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
if [ "$#" -ne 1 ]; then
    print_usage
    exit 1
fi

if [ -z "$1" ] ; then
    target="${base}model/ontologies/"
else
    target="$1"
fi

content_type="text/turtle"

turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="@prefix lsm:	<https://w3id.org/atomgraph/linkeddatahub/admin/sitemap/templates#> .\n"
turtle+="@prefix rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
turtle+="_:arg a lsm:Source .\n"
turtle+="_:arg ldt:paramName \"source\".\n"
turtle+="_:arg rdf:value <${source}>.\n"

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | curl -s -k -E "$cert_pem_file":"$cert_password" -d @- -H "Content-Type: $content_type" -H "Accept: text/turtle" "$target" -s -D -