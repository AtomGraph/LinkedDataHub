#!/bin/bash

set -E
trap onexit ERR

### This script is specific to LinkedDataHub Cloud version. See https://linkeddatahub.com/

function onexit() {
    local exit_status=${1:-$?}
    echo "Exiting $0 with $exit_status"
    exit "$exit_status"
}

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
        --app-base)
        app_base="$2"
        shift # past argument
        shift # past value
        ;;
        --stylesheet)
        stylesheet="$2"
        shift # past argument
        shift # past value
        ;;
        --public)
        public=true
        shift # past value
        ;;
        --logo)
        logo="$2"
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
if [ -z "$app_base" ] ; then
    echo '--app-base not set'
    exit 1
fi

args=()
args+=("-f")
args+=("${cert_pem_file}")
args+=("-p")
args+=("${cert_password}")
args+=("-c")
args+=("https://w3id.org/atomgraph/linkeddatahub/apps/hierarchy#EndUserApplicationLevel2") # class
args+=("-t")
args+=("text/turtle") # content type
args+=("${base}create") # URL

turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix ac:	<https://w3id.org/atomgraph/client#> .\n"
turtle+="@prefix lapp:	<https://w3id.org/atomgraph/linkeddatahub/apps/domain#> .\n"
turtle+="_:app dct:title \"${title}\" .\n"
turtle+="_:app ldt:base <${app_base}> .\n"

if [ -n "$description" ] ; then
    turtle+="_:app dct:description \"${description}\" .\n"
fi
if [ -n "$stylesheet" ] ; then
    turtle+="_:app ac:stylesheet <${stylesheet}> .\n"
fi
if [ -n "$public" ] ; then
    turtle+="_:app lapp:public ${public} .\n"
fi
if [ -n "$logo" ] ; then
    turtle+="_:app foaf:logo <${logo}> .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../create-document.sh "${args[@]}"