#!/bin/bash

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
    --import)
    import="$2"
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
    echo '--import not set'
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Only one default argument is allowed"
    exit 1
fi

ontology_doc=$1

# extract ontology URI and graph URI from app document N-Triples description (slashes in ${ontology_doc} need to be escaped before passing to sed)

ontology=$(curl -s -v -k -E ${cert_pem_file}:${cert_password} "${ontology_doc}" -H "Accept: application/n-triples" | cat | sed -rn "s/<${ontology_doc//\//\\/}> <http:\/\/xmlns.com\/foaf\/0.1\/primaryTopic> <(.*)> \./\1/p")

graph_doc=$(curl -s -v -k -E ${cert_pem_file}:${cert_password} "${ontology_doc}" -H "Accept: application/n-triples" | cat | sed -rn "s/<${ontology_doc//\//\\/}> <http:\/\/rdfs\.org\/ns\/void#inDataset> <(.*)#this> \./\1/p")

sparql+="PREFIX owl:	<http://www.w3.org/2002/07/owl#>\n"
sparql+="INSERT DATA {\n"
sparql+="  GRAPH <${graph_doc}> {\n"
sparql+="    <${ontology}> owl:imports <${import}> .\n"
sparql+="  }\n"
sparql+="}\n"

# PATCH SPARQL to the named graph

echo -e "$sparql" | curl -X PATCH --data-binary @- -v -k -E ${cert_pem_file}:${cert_password} $graph_doc -H "Content-Type: application/sparql-update"