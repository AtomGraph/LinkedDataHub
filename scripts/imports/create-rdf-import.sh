#!/bin/bash

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
    echo '-f|--cert-pem-file not set'
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
if [ -z "$title" ] ; then
    echo '--title not set'
    exit 1
fi
if [ -z "$action" ] ; then
    echo '--action not set'
    exit 1
fi
if [ -z "$query" ] ; then
    echo '--query not set'
    exit 1
fi
if [ -z "$file" ] ; then
    echo '--file not set'
    exit 1
fi

container="${base}imports/"

# if target URL is not provided, it equals container
if [ -z "$1" ] ; then
    args+=("${container}")
fi

args+=("-f")
args+=("${cert_pem_file}")
args+=("-p")
args+=("${cert_password}")
args+=("-c")
args+=("${base}ns#RDFImport") # class
args+=("-t")
args+=("text/turtle") # content type

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix apl:	<https://w3id.org/atomgraph/linkeddatahub/domain#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix spin:	<http://spinrdf.org/spin#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="_:import a ns:RDFImport .\n"
turtle+="_:import dct:title \"${title}\" .\n"
turtle+="_:import spin:query <${query}> .\n"
turtle+="_:import apl:action <${action}> .\n"
turtle+="_:import apl:file <${file}> .\n"
turtle+="_:import foaf:isPrimaryTopicOf _:item .\n"
turtle+="_:item a ns:ImportItem .\n"
turtle+="_:item sioc:has_container <${container}> .\n"
turtle+="_:item dct:title \"${title}\" .\n"
turtle+="_:item foaf:primaryTopic _:import .\n"

if [ -n "$description" ] ; then
    turtle+="_:import dct:description \"${description}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

# set env values in the Turtle doc and sumbit it to the server

# make Jena scripts available
export PATH=$PATH:$JENA_HOME/bin

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../create-document.sh "${args[@]}"