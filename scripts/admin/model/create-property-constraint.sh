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
    --property)
    property="$2"
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

args+=("-c")
args+=("${base}ns#MissingPropertyValue") # class
args+=("-t")
args+=("text/turtle") # content type
args+=("${base}model/constraints/") # container

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix sp:	<http://spinrdf.org/sp#> .\n"
turtle+="_:constraint a ns:MissingPropertyValue .\n"
turtle+="_:constraint rdfs:label \"${label}\" .\n"
turtle+="_:constraint sp:arg1 <${property}> .\n"
turtle+="_:constraint foaf:isPrimaryTopicOf _:item .\n"
turtle+="_:constraint rdfs:isDefinedBy <../ns/domain#> .\n"
turtle+="_:item a ns:ConstraintItem .\n"
turtle+="_:item dct:title \"${label}\" .\n"
turtle+="_:item foaf:primaryTopic _:constraint .\n"

if [ ! -z "$comment" ] ; then
    turtle+="_:constraint rdfs:comment \"${comment}\" .\n"
fi
if [ ! -z "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

# set env values in the Turtle doc and sumbit it to the server

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# submit Turtle doc to the server
echo -e $turtle | turtle --base="${base}" | ../../create-document.sh "${args[@]}"