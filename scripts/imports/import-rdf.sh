#!/bin/bash
set -E
trap onexit ERR

function onexit() {
    local exit_status=${1:-$?}
    echo "Exiting $0 with $exit_status"
    exit "$exit_status"
}

print_usage()
{
    printf "Transforms CSV data into RDF using a SPARQL query and imports it.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "  --request-base BASE_URI              Request base URI\n"
    printf "\n"
    printf "  --title TITLE                        Title of the container\n"
    printf "  --description DESCRIPTION            Description of the container (optional)\n"
    printf "  --slug STRING                         String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --action CONTAINER_URI               URI of the target container\n"
    printf "  --query-file ABS_PATH                Absolute path to the text file with the SPARQL query string (optional)\n"
    printf "  --query-doc-slug STRING              String that will be used as the query's URI path segment (optional)\n"
    printf "  --file ABS_PATH                      Absolute path to the CSV file (optional)\n"
    printf "  --file-slug STRING                   String that will be used as the file's URI path segment (optional)\n"
    printf "  --file-doc-slug STRING               String that will be used as the file document's URI path segment (optional)\n"
    printf "  --file-content-type MEDIA_TYPE       Media type of the file\n"
    printf "  --import-slug STRING                 String that will be used as the import's URI path segment (optional)\n"
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
        --request-base)
        request_base="$2"
        shift # past argument
        shift # past value
        ;;
        --title)
        title="$2"
        shift # past argument
        shift # past value
        ;;
        --action)
        action="$2"
        shift # past argument
        shift # past value
        ;;
        --query-file)
        query_file="$2"
        shift # past argument
        shift # past value
        ;;
        --query-doc-slug)
        query_doc_slug="$2"
        shift # past argument
        shift # past value
        ;;
        --file)
        file="$2"
        shift # past argument
        shift # past value
        ;;
        --file-slug)
        file_slug="$2"
        shift # past argument
        shift # past value
        ;;
        --file-doc-slug)
        file_doc_slug="$2"
        shift # past argument
        shift # past value
        ;;
        --file-content-type)
        file_content_type="$2"
        shift # past argument
        shift # past value
        ;;
        --import-slug)
        import_slug="$2"
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
if [ -z "$action" ] ; then
    print_usage
    exit 1
fi
if [ -z "$file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$file_content_type" ] ; then
    print_usage
    exit 1
fi

if [ -z "$request_base" ] ; then
    request_base="$base"
fi

if [ -n "$query_file" ] ; then
    query_container="${request_base}queries/"
    query_doc=$(./create-query.sh -b "$base" -f "$cert_pem_file" -p "$cert_password" --title "$title" --slug "$query_doc_slug" --query-file "$query_file" "$query_container")
    query_doc=$(echo "$query_doc" | sed -e "s|$base|$request_base|g")

    pushd . > /dev/null && cd "$SCRIPT_ROOT"

    query_ntriples=$(./get-document.sh -f "$cert_pem_file" -p "$cert_password" --accept 'application/n-triples' "$query_doc")

    popd > /dev/null

    query=$(echo "$query_ntriples" | grep '<http://xmlns.com/foaf/0.1/primaryTopic>' | cut -d " " -f 3 | cut -d "<" -f 2 | cut -d ">" -f 1) # cut < > from URI
fi

file_container="${request_base}files/"
file_doc=$(./create-file.sh -b "$base" -f "$cert_pem_file" -p "$cert_password" --title "$title" --slug "$file_doc_slug" --file-slug "$file_slug" --file "$file" --file-content-type "$file_content_type" "$file_container")
file_doc=$(echo "$file_doc" | sed -e "s|$base|$request_base|g")

pushd . > /dev/null && cd "$SCRIPT_ROOT"

file_ntriples=$(./get-document.sh -f "$cert_pem_file" -p "$cert_password" --accept 'application/n-triples' "$file_doc")

popd > /dev/null

file=$(echo "$file_ntriples" | grep '<http://xmlns.com/foaf/0.1/primaryTopic>' | cut -d " " -f 3 | cut -d "<" -f 2 | cut -d ">" -f 1) # cut < > from URI

import_container="${request_base}imports/"
if [ -n "$query" ] ; then
    ./create-rdf-import.sh -b "$base" -f "$cert_pem_file" -p "$cert_password" --title "$title" --slug "$import_slug" --action "$action" --query "$query" --file "$file" "$import_container"
else
    ./create-rdf-import.sh -b "$base" -f "$cert_pem_file" -p "$cert_password" --title "$title" --slug "$import_slug" --action "$action" --file "$file" "$import_container"
fi