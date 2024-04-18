#!/usr/bin/env bash

print_usage()
{
    printf "Appends a chart for SPARQL SELECT query results.\n"
    printf "\n"
    printf "Usage:  %s options\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --title TITLE                        Title of the chart\n"
    printf "  --description DESCRIPTION            Description of the chart (optional)\n"
    printf "  --fragment STRING                    String that will be used as URI fragment identifier (optional)\n"
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
        --fragment)
        fragment="$2"
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

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type

if [ -z "$fragment" ] ; then
    # relative URI that will be resolved against the request URI
    subject="<#${fragment}>"
else
    subject="_:subject"
fi

turtle+="@prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix spin:  <http://spinrdf.org/spin#> .\n"
turtle+="${subject} a ldh:ResultSetChart .\n"
turtle+="${subject} dct:title \"${title}\" .\n"
turtle+="${subject} spin:query <${query}> .\n"
turtle+="${subject} ldh:chartType <${chart_type}> .\n"
turtle+="${subject} ldh:categoryVarName \"${category_var_name}\" .\n"
turtle+="${subject} ldh:seriesVarName \"${series_var_name}\" .\n"

if [ -n "$description" ] ; then
    turtle+="${subject} dct:description \"${description}\" .\n"
fi

# submit Turtle doc to the server
# turtle --base="$base" |

echo -e "$turtle" | ./post.sh "${args[@]}"