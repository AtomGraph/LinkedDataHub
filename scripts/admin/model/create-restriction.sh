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
        --on-property)
        on_property="$2"
        shift # past argument
        shift # past value
        ;;
        --all-values-from)
        all_values_from="$2"
        shift # past argument
        shift # past value
        ;;
        --has-value)
        has_value="$2"
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

container="${base}model/restrictions/"

# allow explicit URIs
if [ -n "$uri" ] ; then
    restriction="<${uri}>" # URI
else
    restriction="_:restriction" # blank node
fi

args+=("-c")
args+=("${base}ns#Restriction") # class
args+=("-t")
args+=("text/turtle") # content type
args+=("${container}") # container

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix owl:	<http://www.w3.org/2002/07/owl#> .\n"
turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix spin:	<http://spinrdf.org/spin#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="${restriction} a ns:Restriction .\n"
turtle+="${restriction} rdfs:label \"${label}\" .\n"
turtle+="${restriction} foaf:isPrimaryTopicOf _:item .\n"
turtle+="${restriction} rdfs:isDefinedBy <../ns/domain#> .\n"
turtle+="_:item a ns:RestrictionItem .\n"
turtle+="_:item sioc:has_container <${container}> .\n"
turtle+="_:item dct:title \"${label}\" .\n"
turtle+="_:item foaf:primaryTopic ${restriction} .\n"

if [ -n "$comment" ] ; then
    turtle+="${restriction} rdfs:comment \"${comment}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi
if [ -n "$on_property" ] ; then
    turtle+="${restriction} owl:onProperty <$on_property> .\n"
fi
if [ -n "$all_values_from" ] ; then
    turtle+="${restriction} owl:allValuesFrom <$all_values_from> .\n"
fi
if [ -n "$has_value" ] ; then
    turtle+="${restriction} owl:hasValue <$has_value> .\n"
fi

# set env values in the Turtle doc and sumbit it to the server

# make Jena scripts available
export PATH=$PATH:$JENA_HOME/bin

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../../create-document.sh "${args[@]}"