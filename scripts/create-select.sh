#!/usr/bin/env bash

print_usage()
{
    printf "Creates a SPARQL SELECT query.\n"
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
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "  --fragment STRING                    String that will be used as URI fragment identifier (optional)\n"
    printf "\n"
    printf "  --query-file ABS_PATH                Absolute path to the text file with the SPARQL query string\n"
    printf "  --service SERVICE_URI                URI of the SPARQL service specific to this query (optional)\n"
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
        --fragment)
        fragment="$2"
        shift # past argument
        shift # past value
        ;;
        --query-file)
        query_file="$2"
        shift # past argument
        shift # past value
        ;;
        --service)
        service="$2"
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
if [ -z "$query_file" ] ; then
    print_usage
    exit 1
fi

container="${base}queries/"
query=$(<"$query_file") # read query string from file

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type
args+=("${base}service")

turtle+="@prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix sp:	<http://spinrdf.org/sp#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="_:query a sp:Select .\n"
turtle+="_:query dct:title \"${title}\" .\n"
turtle+="_:query sp:text \"\"\"${query}\"\"\" .\n"
turtle+="_:item a dh:Item .\n"
turtle+="_:item dct:title \"${title}\" .\n"
turtle+="_:item foaf:primaryTopic _:query .\n"
turtle+="_:item sioc:has_container <${container}> .\n"

if [ -n "$service" ] ; then
    turtle+="_:query ldh:service <${service}> .\n"
fi
if [ -n "$description" ] ; then
    turtle+="_:query dct:description \"${description}\" .\n"
fi
if [ -n "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi
if [ -n "$fragment" ] ; then
    turtle+="_:query ldh:fragment \"${fragment}\" .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ./create-document.sh "${args[@]}"