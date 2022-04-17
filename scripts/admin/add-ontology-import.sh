#!/usr/bin/env bash

print_usage()
{
    printf "Adds owl:import statement to ontology.\n"
    printf "\n"
    printf "Usage:  %s options ONTOLOGY_DOC_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
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
    print_usage
    exit 1
fi
if [ "$#" -ne 1 ]; then
    print_usage
    exit 1
fi

ontology_doc="$1"
target="$1"

if [ -n "$proxy" ]; then
    # rewrite target hostname to proxy hostname
    target_host=$(echo "$target" | cut -d '/' -f 1,2,3)
    proxy_host=$(echo "$proxy" | cut -d '/' -f 1,2,3)
    target="${target/$target_host/$proxy_host}"
fi

sparql+="PREFIX owl:	<http://www.w3.org/2002/07/owl#>\n"
sparql+="PREFIX foaf:	<http://xmlns.com/foaf/0.1/>\n"
sparql+="INSERT {\n"
sparql+="  GRAPH <${ontology_doc}> {\n"
sparql+="    ?ontology owl:imports <${import}> .\n"
sparql+="  }\n"
sparql+="}\n"
sparql+="WHERE {\n"
sparql+="  GRAPH <${ontology_doc}> {\n"
sparql+="    <${ontology_doc}> foaf:primaryTopic ?ontology .\n"
sparql+="  }\n"
sparql+="}\n"

# PATCH SPARQL to the named graph

echo -e "$sparql" | curl -X PATCH --data-binary @- -v -k -E "$cert_pem_file":"$cert_password" "$target" -H "Content-Type: application/sparql-update"