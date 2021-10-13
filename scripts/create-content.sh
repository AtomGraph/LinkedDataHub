#!/bin/bash

print_usage()
{
    printf "Creates a content instance.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "\n"
    printf "  --first RESOURCE_URI                 URI of the content element (query, chart etc.)\n"
    printf "  --rest RESOURCE_URI                  URI of the following content (optional)\n"
    printf "  --title TITLE                        Title of the content (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
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
        --uri)
        uri="$2"
        shift # past argument
        shift # past value
        ;;
        --title)
        title="$2"
        shift # past argument
        shift # past value
        ;;
        --first)
        first="$2"
        shift # past argument
        shift # past value
        ;;
        --rest)
        rest="$2"
        shift # past argument
        shift # past value
        ;;
        --slug)
        slug="$2"
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
if [ -z "$first" ] ; then
    print_usage
    exit 1
fi

# allow explicit URIs
if [ -n "$uri" ] ; then
    content="<${uri}>" # URI
else
    content="_:content" # blank node
fi

args+=("-f")
args+=("${cert_pem_file}")
args+=("-p")
args+=("${cert_password}")
args+=("-t")
args+=("text/turtle") # content type

turtle+="@prefix rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix apl:	<https://w3id.org/atomgraph/linkeddatahub/domain#> .\n"
turtle+="${content} a apl:Content .\n"
turtle+="${content} rdf:first <${first}> .\n"

if [ -n "$rest" ] ; then
    turtle+="${content} rdf:rest <${rest}> .\n"
else
    turtle+="${content} rdf:rest rdf:nil .\n"
fi
if [ -n "$title" ] ; then
    turtle+="${content} dct:title \"${title}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
    turtle+="${content} dh:slug \"${slug}\" .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ./create-document.sh "${args[@]}"