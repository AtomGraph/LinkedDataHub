#!/bin/bash

print_usage()
{
    printf "Adds agent to an agent group.\n"
    printf "\n"
    printf "Usage:  %s options GROUP_DOC_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "\n"
    printf "  --agent AGENT_URI                    URI of the agent\n"
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
    --agent)
    agent="$2"
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

if [ -z "$agent" ] ; then
    print_usage
    exit 1
fi
if [ "$#" -ne 1 ]; then
    print_usage
    exit 1
fi

group_doc="$1"

# extract group URI and graph URI from app document N-Triples description (slashes in ${group_doc} need to be escaped before passing to sed)

group=$(curl -s -k -E "$cert_pem_file":"$cert_password" "$group_doc" -H "Accept: application/n-triples" | cat | sed -rn "s/<${group_doc//\//\\/}> <http:\/\/xmlns.com\/foaf\/0.1\/primaryTopic> <(.*)> \./\1/p")

sparql+="PREFIX foaf:	<http://xmlns.com/foaf/0.1/>\n"
sparql+="INSERT DATA {\n"
sparql+="  GRAPH <${group_doc}> {\n"
sparql+="    <${group}> foaf:member <${agent}> .\n"
sparql+="  }\n"
sparql+="}\n"

# PATCH SPARQL to the named graph

echo -e "$sparql" | curl -X PATCH --data-binary @- -s -k -E "$cert_pem_file":"$cert_password" "$group_doc" -H "Content-Type: application/sparql-update"