#!/bin/bash

print_usage()
{
    printf "Adds owl:import statement to ontology.\n"
    printf "\n"
    printf "Usage:  %s options ONTOLOGY_DOC_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the admin application\n"
    printf "  --request-base BASE_URI              Request base URI\n"
    printf "\n"
    printf "  --import IMPORT_URI                  URI of the imported ontology\n"
}

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
        --import)
        import="$2"
        shift # past argument
        shift # past value
        ;;
        --request-base)
        request_base="$2"
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

if [ -z "$import" ] ; then
    print_usage
    exit 1
fi
if [ "$#" -ne 1 ]; then
    print_usage
    exit 1
fi

ontology_doc="$1"

if [ -z "$request_base" ] ; then
    ontology_doc_uri="$ontology_doc"
else
    ontology_doc_uri=$(echo "$ontology_doc" | sed -e "s|$request_base|$base|g")
fi

# extract ontology URI and graph URI from app document N-Triples description (slashes in ${ontology_doc} need to be escaped before passing to sed)

ontology_doc_ntriples=$(curl -s -k -E "$cert_pem_file":"$cert_password" "$ontology_doc" -H "Accept: application/n-triples")
ontology=$(echo "$ontology_doc_ntriples" | sed -rn "s/<${ontology_doc_uri//\//\\/}> <http:\/\/xmlns.com\/foaf\/0.1\/primaryTopic> <(.*)> \./\1/p")

sparql+="PREFIX owl:	<http://www.w3.org/2002/07/owl#>\n"
sparql+="INSERT DATA {\n"
sparql+="  GRAPH <${ontology_doc}> {\n"
sparql+="    <${ontology}> owl:imports <${import}> .\n"
sparql+="  }\n"
sparql+="}\n"

# PATCH SPARQL to the named graph

echo -e "$sparql" | curl -X PATCH --data-binary @- -v -k -E "$cert_pem_file":"$cert_password" "$ontology_doc" -H "Content-Type: application/sparql-update"