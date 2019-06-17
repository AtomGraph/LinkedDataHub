#!/bin/bash

# New version of scripts that accept named arguments, e.g.: ./create-container.sh -f ../../linkeddatahub-apps/certs/martynas.stage.localhost.pem -p XXXXXX -b https://localhost:4443/demo/city-graph/  https://localhost:4443/demo/city-graph/ --title "Test" --description "This is a container"

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
    --select)
    select="$2"
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
set -- "${args[@]}" # restore args parameters

if [ -z "$base" ] ; then
    echo '-b|--base not set'
    exit 1
fi
if [ -z "$title" ] ; then
    echo '--title not set'
    exit 1
fi

args+=("-c")
args+=("${base}ns/default#Container")
args+=("-t")
args+=("text/turtle")

turtle+="@prefix def:	<ns/default#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="_:container a def:Container .\n"
turtle+="_:container dct:title \"${title}\" .\n"
if [ -n "$select" ] ; then
    turtle+="_:container dh:select <${select}> .\n"
fi
if [ -n "$description" ] ; then
    turtle+="_:container dct:description \"${description}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="_:container dh:slug \"${slug}\" .\n"
fi

echo -e "$turtle" | turtle --base="${base}" | ./create-document.sh "${args[@]}"