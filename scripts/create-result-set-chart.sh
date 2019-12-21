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
        --endpoint)
        endpoint="$2"
        shift # past argument
        shift # past value
        ;;
        --query)
        query="$2"
        shift # past argument
        shift # past value
        ;;
        --chart-type)
        chart_type="$2"
        shift # past argument
        shift # past value
        ;;
        --category-var-name)
        category_var_name="$2"
        shift # past argument
        shift # past value
        ;;
        --series-var-name)
        series_var_name="$2"
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
if [ -z "$endpoint" ] ; then # TO-DO: make obsolete/optional?
    echo '--endpoint not set'
    exit 1
fi
if [ -z "$query" ] ; then
    echo '--query not set'
    exit 1
fi
if [ -z "$chart_type" ] ; then
    echo '--chart-type not set'
    exit 1
fi
if [ -z "$category_var_name" ] ; then
    echo '--category-var-name not set'
    exit 1
fi
if [ -z "$series_var_name" ] ; then
    echo '--series-var-name not set'
    exit 1
fi

container="${base}charts/"

args+=("-c")
args+=("${base}ns#ResultSetChart") # class
args+=("-t")
args+=("text/turtle") # content type
args+=("${container}") # container

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix spin:  <http://spinrdf.org/spin#> .\n"
turtle+="@prefix apl:	<http://atomgraph.com/ns/platform/domain#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="_:chart a ns:ResultSetChart .\n"
turtle+="_:chart dct:title \"${title}\" .\n"
turtle+="_:chart apl:endpoint <${endpoint}> .\n" # TO-DO: remove
turtle+="_:chart spin:query <${query}> .\n"
turtle+="_:chart apl:chartType <${chart_type}> .\n"
turtle+="_:chart apl:categoryVarName \"${category_var_name}\" .\n"
turtle+="_:chart apl:seriesVarName \"${series_var_name}\" .\n"
turtle+="_:chart foaf:isPrimaryTopicOf _:item .\n"
turtle+="_:item a ns:ChartItem .\n"
turtle+="_:item dct:title \"${title}\" .\n"
turtle+="_:item sioc:has_container <${container}> .\n"
turtle+="_:item foaf:primaryTopic _:chart .\n"

if [ -n "$description" ] ; then
    turtle+="_:chart dct:description \"${description}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

# set env values in the Turtle doc and sumbit it to the server

# make Jena scripts available
export PATH="$PATH":"$JENA_HOME/bin"

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ./create-document.sh "${args[@]}"