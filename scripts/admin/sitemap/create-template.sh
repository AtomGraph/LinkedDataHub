#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

args=()
params=() # --param can have multiple values, so we need an array
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -b|--base)
    base="$2"
    shift # past argument
    shift # past value
    ;;
    --label)
    label="$2"
    shift # past argument
    shift # past value
    ;;
    --comment)
    comment="$2"
    shift # past argument
    shift # past value
    ;;
    --slug)
    slug="$2"
    shift # past argument
    shift # past value
    ;;
    --uri)
    uri="$2"
    shift # past argument
    shift # past value
    ;;
    --query)
    query="$2"
    shift # past argument
    shift # past value
    ;;
    --match)
    match="$2"
    shift # past argument
    shift # past value
    ;;
    --extends)
    extends="$2"
    shift # past argument
    shift # past value
    ;;
    --param)
    params+=("$2")
    shift # past argument
    shift # past value
    ;;
    --is-defined-by)
    is_defined_by="$2"
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
if [ -z "$label" ] ; then
    echo '--label not set'
    exit 1
fi
if ( [ -z "$extends" ] && [ -z "$query" ] ) || ( [ -z "$extends" ] && [ -z "$match" ] ) ; then
    echo '--extends or --query and --match not set'
    exit 1
fi
if [ -z "$is_defined_by" ] ; then
    echo '--is-defined-by not set'
    exit 1
fi

args+=("-c")
args+=("${base}ns#Template") # class
args+=("-t")
args+=("text/turtle") # content type
args+=("${base}sitemap/templates/") # container

# allow explicit URIs
if [ ! -z "$uri" ] ; then
    template="<${uri}>" # URI
else
    template="_:template" # blank node
fi

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="${template} a ns:Template .\n"
turtle+="${template} rdfs:label \"${label}\" .\n"
turtle+="${template} foaf:isPrimaryTopicOf _:item .\n"
turtle+="${template} rdfs:isDefinedBy <${is_defined_by}> .\n"
turtle+="_:item a ns:TemplateItem .\n"
turtle+="_:item dct:title \"${label}\" .\n"
turtle+="_:item foaf:primaryTopic ${template} .\n"

if [ ! -z "$comment" ] ; then
    turtle+="${template} rdfs:comment \"${comment}\" .\n"
fi
if [ ! -z "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

if [ ! -z "$query" ] ; then
    turtle+="${template} ldt:query <${query}> .\n"
fi
if [ ! -z "$extends" ] ; then
    turtle+="${template} ldt:extends <${extends}> .\n"
fi
if [ ! -z "$match" ] ; then
    turtle+="${template} ldt:match \"${match}\" .\n"
fi

for param in "${params[@]}"
do
    turtle+="${template} ldt:param <${param}> .\n"
done

# set env values in the Turtle doc and sumbit it to the server

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="${base}" | ../../create-document.sh "${args[@]}"