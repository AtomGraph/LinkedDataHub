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
        --repository)
        repository="$2"
        shift # past argument
        shift # past value
        ;;
        --auth-token)
        auth_token="$2"
        shift # past argument
        shift # past value
        ;;
        --auth-user)
        auth_user=true
        shift # past value
        ;;
        --auth-pwd)
        auth_pwd="$2"
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
if [ -z "$repository" ] ; then
    echo '--repository not set'
    exit 1
fi
if [ -z "$title" ] ; then
    echo '--title not set'
    exit 1
fi

container="${base}services/"

# if target URL is not provided, it equals container
if [ -z "$1" ] ; then
    args+=("${container}")
fi

args+=("-f")
args+=("${cert_pem_file}")
args+=("-p")
args+=("${cert_password}")
args+=("-c")
args+=("${base}ns#DydraService") # class
args+=("-t")
args+=("text/turtle") # content type

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix a:	<https://w3id.org/atomgraph/core#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dydra: <http://dydra.com/ns#> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix sd:	<http://www.w3.org/ns/sparql-service-description#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="_:service a ns:DydraService .\n"
turtle+="_:service dct:title \"${title}\" .\n"
turtle+="_:service dydra:repository <${repository}> .\n"
turtle+="_:service sd:supportedLanguage sd:SPARQL11Query .\n"
turtle+="_:service sd:supportedLanguage sd:SPARQL11Update .\n"
turtle+="_:service foaf:isPrimaryTopicOf _:item .\n"
turtle+="_:item a ns:ServiceItem .\n"
turtle+="_:item sioc:has_container <${container}> .\n"
turtle+="_:item dct:title \"${title}\" .\n"
turtle+="_:item foaf:primaryTopic _:service .\n"

if [ -n "$auth_token" ] ; then
    turtle+="_:service <urn:dydra:accessToken> \"${auth_token}\" .\n"
fi
if [ -n "$auth_user" ] ; then
    turtle+="_:service a:authUser \"${auth_user}\" .\n"
fi
if [ -n "$auth_pwd" ] ; then
    turtle+="_:service a:authPwd \"${auth_pwd}\" .\n"
fi
if [ -n "$description" ] ; then
    turtle+="_:query dct:description \"${description}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ./create-document.sh "${args[@]}"