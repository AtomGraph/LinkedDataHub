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
    --delimiter)
    delimiter="$2"
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
if [ -z "$delimiter" ] ; then
    echo '--delimiter not set'
    exit 1
fi

args+=("-c")
args+=("${base}ns#CSVImport") # class
args+=("-t")
args+=("text/turtle") # content type
args+=("${base}imports/") # container

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix apl:	<http://atomgraph.com/ns/platform/domain#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix dydra:	<http://dydra.com/ns#> .\n"
turtle+="@prefix srv:	<http://jena.hpl.hp.com/Service#> .\n"
turtle+="@prefix spin:	<http://spinrdf.org/spin#> .\n"
turtle+="_:import a ns:CSVImport .\n"
turtle+="_:import dct:title \"${title}\" .\n"
turtle+="_:import spin:query <${query}> .\n"
turtle+="_:import apl:action <${action}> .\n"
turtle+="_:import apl:file <${file}> .\n"
turtle+="_:import apl:delimiter \"${delimiter}\" .\n"
turtle+="_:import foaf:isPrimaryTopicOf _:item .\n"
turtle+="_:item a ns:ImportItem .\n"
turtle+="_:item dct:title \"${title}\" .\n"
turtle+="_:item foaf:primaryTopic _:import .\n"

if [ ! -z "$description" ] ; then
    turtle+="_:import dct:description \"${description}\" .\n"
fi
if [ ! -z "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

# set env values in the Turtle doc and sumbit it to the server

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# submit Turtle doc to the server
echo -e $turtle | turtle --base="${base}" | ../create-document.sh "${args[@]}"