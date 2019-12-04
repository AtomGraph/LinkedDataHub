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
    --query-file)
    query_file="$2"
    shift # past argument
    shift # past value
    ;;
    --endpoint)
    endpoint="$2"
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
if [ -z "$query_file" ] ; then
    echo '--query-file not set'
    exit 1
fi

query=$(<"$query_file") # read query string from file

args+=("-c")
args+=("${base}ns#Construct") # class
args+=("-t")
args+=("text/turtle") # content type
args+=("${base}queries/") # container

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix sp:	<http://spinrdf.org/sp#> .\n"
turtle+="@prefix apl:	<http://atomgraph.com/ns/platform/domain#> .\n"
turtle+="_:query a ns:Select .\n"
turtle+="_:query dct:title \"${title}\" .\n"
turtle+="_:query sp:text \"\"\"${query}\"\"\" .\n"
turtle+="_:query foaf:isPrimaryTopicOf _:item .\n"
turtle+="_:item a ns:QueryItem .\n"
turtle+="_:item dct:title \"${title}\" .\n"
turtle+="_:item foaf:primaryTopic _:query .\n"

if [ -n "$endpoint" ] ; then
    turtle+="_:query apl:endpoint <${endpoint}> .\n"
fi
if [ -n "$description" ] ; then
    turtle+="_:query dct:description \"${description}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

# set env values in the Turtle doc and sumbit it to the server

# make Jena scripts available
export PATH=$PATH:$JENA_HOME/bin

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ./create-document.sh "${args[@]}"