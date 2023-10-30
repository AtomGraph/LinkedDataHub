#!/usr/bin/env bash

print_usage()
{
    printf "Transforms CSV data into RDF using a SPARQL query and imports it.\n"
    printf "\n"
    printf "Usage:  %s options\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --title TITLE                        Title of the container\n"
    printf "  --description DESCRIPTION            Description of the container (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "  --fragment STRING                    String that will be used as URI fragment identifier (optional)\n"
    printf "\n"
    printf "  --query QUERY_URI                    URI of the CONSTRUCT mapping query\n"
    printf "  --file FILE_URI                      URI of the CSV file\n"
    printf "  --delimiter CHAR                     Delimiter char (default: ',')\n"
}

hash turtle 2>/dev/null || { echo >&2 "turtle not on \$PATH. Need to set \$JENA_HOME. Aborting."; exit 1; }

urlencode() {
  python -c 'import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], sys.argv[2]))' \
    "$1" "$urlencode_safe"
}

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
if [ -z "$file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$delimiter" ] ; then
    print_usage
    exit 1
fi

if [ -z "$slug" ] ; then
    slug=$(uuidgen | tr '[:upper:]' '[:lower:]') # lowercase
fi
encoded_slug=$(urlencode "$slug")

container="${base}imports/"

args+=("-f")
args+=("$cert_pem_file")
args+=("-p")
args+=("$cert_password")
args+=("-t")
args+=("text/turtle") # content type
args+=("${container}${encoded_slug}/")

turtle+="@prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix spin:	<http://spinrdf.org/spin#> .\n"
turtle+="@prefix sioc:	<http://rdfs.org/sioc/ns#> .\n"
turtle+="_:import a ldh:CSVImport .\n"
turtle+="_:import dct:title \"${title}\" .\n"
turtle+="_:import spin:query <${query}> .\n"
turtle+="_:import ldh:file <${file}> .\n"
turtle+="_:import ldh:delimiter \"${delimiter}\" .\n"
turtle+="<${container}${encoded_slug}/> a dh:Item .\n"
turtle+="<${container}${encoded_slug}/> foaf:primaryTopic _:import .\n"
turtle+="<${container}${encoded_slug}/> sioc:has_container <${container}> .\n"
turtle+="<${container}${encoded_slug}/> dct:title \"${title}\" .\n"

if [ -n "$description" ] ; then
    turtle+="_:import dct:description \"${description}\" .\n"
fi
if [ -n "$fragment" ] ; then
    turtle+="_:import ldh:fragment \"${fragment}\" .\n"
fi

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="$base" | ../put.sh "${args[@]}"