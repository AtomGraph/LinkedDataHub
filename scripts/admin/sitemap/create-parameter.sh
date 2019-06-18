#!/bin/bash

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH. Need to set \$JENA_HOME. Aborting."; exit 1; }

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
    --uri)
    uri="$2"
    shift # past argument
    shift # past value
    ;;
    --predicate)
    predicate="$2"
    shift # past argument
    shift # past value
    ;;
    --value-type)
    value_type="$2"
    shift # past argument
    shift # past value
    ;;
    --optional)
    optional=true
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
if [ -z "$predicate" ] ; then
    echo '--predicate not set'
    exit 1
fi
if [ -z "$value_type" ] ; then
    echo '--value-type not set'
    exit 1
fi
if [ -z "$optional" ] ; then
    echo '--optional not set'
    exit 1
fi
if [ -z "$is_defined_by" ] ; then
    echo '--is-defined-by not set'
    exit 1
fi

args+=("-c")
args+=("${base}ns#Parameter") # class
args+=("-t")
args+=("text/turtle") # content type
args+=("${base}sitemap/parameters/") # container

# allow explicit URIs
if [ -n "$uri" ] ; then
    param="<${uri}>" # URI
else
    param="_:param" # blank node
fi

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix spl:	<http://spinrdf.org/spl#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="${param} a ns:Parameter .\n"
turtle+="${param} rdfs:label \"${label}\" .\n"
turtle+="${param} foaf:isPrimaryTopicOf _:item .\n"
turtle+="${param} rdfs:isDefinedBy <${is_defined_by}> .\n"
turtle+="_:item a ns:ParameterItem .\n"
turtle+="_:item dct:title \"${label}\" .\n"
turtle+="_:item foaf:primaryTopic ${param} .\n"

if [ -n "$comment" ] ; then
    turtle+="${param} rdfs:comment \"${comment}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

if [ -n "$predicate" ] ; then
    turtle+="${param} spl:predicate <${predicate}> .\n"
fi
if [ -n "$value_type" ] ; then
    turtle+="${param} spl:valueType <${value_type}> .\n"
fi
if [ -n "$optional" ] ; then
    turtle+="${param} spl:optional true .\n"
fi

# set env values in the Turtle doc and sumbit it to the server

# make Jena scripts available
export PATH=$PATH:$JENA_HOME/bin

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../../create-document.sh "${args[@]}"