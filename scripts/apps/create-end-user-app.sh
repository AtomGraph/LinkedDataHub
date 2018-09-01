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
    --app-base)
    app_base="$2"
    shift # past argument
    shift # past value
    ;;
    --service)
    service="$2"
    shift # past argument
    shift # past value
    ;;
    --admin-app)
    admin_app="$2"
    shift # past argument
    shift # past value
    ;;
    --public)
    public=true
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
if [ -z "$app_base" ] ; then
    echo '--app-base not set'
    exit 1
fi
if [ -z "$admin_app" ] ; then
    echo '--admin-app not set'
    exit 1
fi
if [ -z "$service" ] ; then
    echo '--service not set'
    exit 1
fi

args+=("-c")
args+=("${base}ns#EndUserApplication") # class
args+=("-t")
args+=("text/turtle") # content type
args+=("${base}apps/end-user/") # container

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix lapp:	<http://linkeddatahub.com/ns/apps/domain#> .\n"
turtle+="_:app a ns:EndUserApplication .\n"
turtle+="_:app dct:title \"${title}\" .\n"
turtle+="_:app lapp:adminApplication <${admin_app}> .\n"
turtle+="_:app ldt:base <${app_base}> .\n"
turtle+="_:app ldt:ontology <${app_base}ns#> .\n"
turtle+="_:app ldt:service <${service}> .\n"
turtle+="_:app foaf:isPrimaryTopicOf _:item .\n"
turtle+="_:item a ns:EndUserApplicationItem .\n"
turtle+="_:item dct:title \"${title}\" .\n"
turtle+="_:item foaf:primaryTopic _:app .\n"

if [ ! -z "$description" ] ; then
    turtle+="_:app dct:description \"${description}\" .\n"
fi
if [ ! -z "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi
if [ ! -z "$public" ] ; then
    turtle+="_:app lapp:public ${public} .\n"
fi

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# submit Turtle doc to the server
echo -e $turtle | turtle --base="${base}" | ../create-document.sh "${args[@]}"