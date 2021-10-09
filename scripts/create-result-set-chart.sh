#!/bin/bash

print_usage()
{
    printf "Creates a chart for SPARQL SELECT query results.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "\n"
    printf "  --title TITLE                        Title of the chart\n"
    printf "  --description DESCRIPTION            Description of the chart (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --query QUERY_URI                    URI of the SELECT query\n"
    printf "  --chart-type TYPE_URI                URI of the chart type\n"
    printf "  --category-var-name CATEGORY_VAR     Name of the variable used as category (without leading '?')\n"
    printf "  --series-var-name SERIES_VAR         Name of the variable used as series (without leading '?')\n"
}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH. Need to set \$JENA_HOME. Aborting."; exit 1; }

args=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -f|--cert-pem-file)
        cert_pem_file="$2"
        shift # past argument
        shift # past value
        ;;
        -p|--cert-password)
        cert_password="$2"
        shift # past argument
        shift # past value
        ;;
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

if [ -z "$cert_pem_file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$cert_password" ] ; then
    print_usage
    exit 1
fi
if [ -z "$base" ] ; then
    print_usage
    exit 1
fi
if [ -z "$title" ] ; then
    print_usage
    exit 1
fi
if [ -z "$query" ] ; then
    print_usage
    exit 1
fi
if [ -z "$chart_type" ] ; then
    print_usage
    exit 1
fi
if [ -z "$category_var_name" ] ; then
    print_usage
    exit 1
fi
if [ -z "$series_var_name" ] ; then
    print_usage
    exit 1
fi

container="${base}charts/"

if [ -z "$1" ]; then
    args+=("${base}service") # default target URL = graph store
fi

args+=("-f")
args+=("${cert_pem_file}")
args+=("-p")
args+=("${cert_password}")
args+=("-t")
args+=("text/turtle") # content type

turtle+="@prefix def:	<https://w3id.org/atomgraph/linkeddatahub/default#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix spin:  <http://spinrdf.org/spin#> .\n"
turtle+="@prefix apl:	<https://w3id.org/atomgraph/linkeddatahub/domain#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="_:chart a def:ResultSetChart .\n"
turtle+="_:chart dct:title \"${title}\" .\n"
turtle+="_:chart spin:query <${query}> .\n"
turtle+="_:chart apl:chartType <${chart_type}> .\n"
turtle+="_:chart apl:categoryVarName \"${category_var_name}\" .\n"
turtle+="_:chart apl:seriesVarName \"${series_var_name}\" .\n"
turtle+="_:chart foaf:isPrimaryTopicOf _:item .\n"
turtle+="_:item a def:Item .\n"
turtle+="_:item dct:title \"${title}\" .\n"
turtle+="_:item sioc:has_container <${container}> .\n"

if [ -n "$description" ] ; then
    turtle+="_:chart dct:description \"${description}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ./create-document.sh "${args[@]}"