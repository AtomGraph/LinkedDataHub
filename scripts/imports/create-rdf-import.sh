#!/bin/bash

print_usage()
{
    printf "Imports RDF data.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "\n"
    printf "  --title TITLE                        Title of the container\n"
    printf "  --description DESCRIPTION            Description of the container (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --action CONTAINER_URI               URI of the target container\n"
    printf "  --query QUERY_URI                    URI of the CONSTRUCT mapping query (optional)\n"
    printf "  --graph GRAPH_URI                    URI of the graph (optional)\n"
    printf "  --file FILE_URI                      URI of the RDF file\n"
}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH. Need to set \$JENA_HOME. Aborting."; exit 1; }

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
        --title)
        title="$2"
        shift # past argument
        shift # past value
        ;;
        --description)
        description="$2"
        shift # past argument
        shift # past value
        ;;
        --slug)
        slug="$2"
        shift # past argument
        shift # past value
        ;;
        --action)
        action="$2"
        shift # past argument
        shift # past value
        ;;
        --graph)
        graph="$2"
        shift # past argument
        shift # past value
        ;;
        --query)
        query="$2"
        shift # past argument
        shift # past value
        ;;
        --file)
        file="$2"
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
if [ -z "$title" ] ; then
    print_usage
    exit 1
fi
if [ -z "$file" ] ; then
    print_usage
    exit 1
fi

container="${base}imports/"

if [ -z "$1" ]; then
    args+=("${base}imports") # default target URL = import endpoint
fi

args+=("-f")
args+=("${cert_pem_file}")
args+=("-p")
args+=("${cert_password}")
args+=("-t")
args+=("text/turtle") # content type

turtle+="@prefix def:	<https://w3id.org/atomgraph/linkeddatahub/default#> .\n"
turtle+="@prefix apl:	<https://w3id.org/atomgraph/linkeddatahub/domain#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="_:import a def:RDFImport .\n"
turtle+="_:import dct:title \"${title}\" .\n"
turtle+="_:import apl:file <${file}> .\n"
turtle+="_:import foaf:isPrimaryTopicOf _:item .\n"
turtle+="_:item a def:Item .\n"
turtle+="_:item sioc:has_container <${container}> .\n"
turtle+="_:item dct:title \"${title}\" .\n"

if [ -n "$action" ] ; then
    turtle+="_:import apl:action <${action}> .\n"
fi
if [ -n "$graph" ] ; then
    turtle+="@prefix sd:	<http://www.w3.org/ns/sparql-service-description#> .\n"
    turtle+="_:import sd:name <${graph}> .\n"
fi
if [ -n "$query" ] ; then
    turtle+="@prefix spin:	<http://spinrdf.org/spin#> .\n"
    turtle+="_:import spin:query <${query}> .\n"
fi
if [ -n "$description" ] ; then
    turtle+="_:import dct:description \"${description}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../create-document.sh "${args[@]}"