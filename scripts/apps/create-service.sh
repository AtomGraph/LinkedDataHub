#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

args=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
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
    --endpoint)
    endpoint="$2"
    shift # past argument
    shift # past value
    ;;
    --graph-store)
    graph_store="$2"
    shift # past argument
    shift # past value
    ;;
    --service-user)
    service_user="$2"
    shift # past argument
    shift # past value
    ;;
    --service-password)
    service_password="$2"
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

if [ -z "$base" ] ; then
    echo '-b|--base not set'
    exit 1
fi
if [ -z "$title" ] ; then
    echo '--title not set'
    exit 1
fi
if [ -z "$endpoint" ] ; then
    echo '--endpoint not set'
    exit 1
fi
if [ -z "$graph_store" ] ; then
    echo '--graph-store not set'
    exit 1
fi

args+=("-c")
args+=("${base}ns#GenericService") # class
args+=("-t")
args+=("text/turtle") # content type
args+=("${base}services/") # container

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix sd:	<http://www.w3.org/ns/sparql-service-description#> .\n"
turtle+="@prefix a:	<http://atomgraph.com/ns/core#> .\n"
turtle+="@prefix srv:	<http://jena.hpl.hp.com/Service#> .\n"
turtle+="_:service a ns:GenericService .\n"
turtle+="_:service dct:title \"${title}\" .\n"
turtle+="_:service sd:endpoint <${endpoint}> .\n"
turtle+="_:service sd:supportedLanguage sd:SPARQL11Query, sd:SPARQL11Update .\n"
turtle+="_:service a:graphStore <${graph_store}> .\n"
turtle+="_:service foaf:isPrimaryTopicOf _:item .\n"
turtle+="_:item a ns:ServiceItem .\n"
turtle+="_:item dct:title \"${title}\" .\n"
turtle+="_:item foaf:primaryTopic _:service .\n"

if [ ! -z "$description" ] ; then
    turtle+="_:service dct:description \"${description}\" .\n"
fi
if [ ! -z "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi
if [ ! -z "$service_user" ] ; then
    turtle+="_:service srv:queryAuthUser \"${service_user}\" .\n"
fi
if [ ! -z "$service_password" ] ; then
    turtle+="_:service srv:queryAuthPwd \"${service_password}\" .\n"
fi

# set env values in the Turtle doc and sumbit it to the server

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="${base}" | ../create-document.sh "${args[@]}"