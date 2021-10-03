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
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --action CONTAINER_URI               URI of the target container\n"
    printf "  --query-file ABS_PATH                Absolute path to the text file with the SPARQL query string\n"
    printf "  --query-doc-slug STRING              String that will be used as the query's URI path segment (optional)\n"
    printf "  --file ABS_PATH                      Absolute path to the CSV file\n"
    printf "  --file-slug STRING                   String that will be used as the file's URI path segment (optional)\n"
    printf "  --file-doc-slug STRING               String that will be used as the file document's URI path segment (optional)\n"
    printf "  --delimiter CHAR                     CSV delimiter char (default: ',')\n"
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
        --delimiter)
        delimiter="$2"
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
if [ -z "$query_file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$file" ] ; then
    print_usage
    exit 1
fi

if [ -z "$request_base" ] ; then
    request_base="$base"
fi

query_doc=$(./create-query.sh -b "$base" -f "$cert_pem_file" -p "$cert_password" --title "$title" --slug "$query_doc_slug" --query-file "$query_file") # "${request_base}service"
query_doc=$(echo "$query_doc" | sed -e "s|$base|$request_base|g")

pushd . > /dev/null && cd "$SCRIPT_ROOT"

query_ntriples=$(./get-document.sh -f "$cert_pem_file" -p "$cert_password" --accept 'application/n-triples' "$query_doc")

popd > /dev/null

query=$(echo "$query_ntriples" | sed -rn "s/<(.*)> <http:\/\/xmlns.com\/foaf\/0.1\/isPrimaryTopicOf> <${query_doc//\//\\/}> \./\1/p")

file_doc=$(./create-file.sh -b "$base" -f "$cert_pem_file" -p "$cert_password" --title "$title" --slug "$file_doc_slug" --file-slug "$file_slug" --file "$file" --file-content-type "text/csv") # TO-DO: "${request_base}uploads"
file_doc=$(echo "$file_doc" | sed -e "s|$base|$request_base|g")

pushd . > /dev/null && cd "$SCRIPT_ROOT"

file_ntriples=$(./get-document.sh -f "$cert_pem_file" -p "$cert_password" --accept 'application/n-triples' "$file_doc")

popd > /dev/null

file=$(echo "$file_ntriples" | sed -rn "s/<(.*)> <http:\/\/xmlns.com\/foaf\/0.1\/isPrimaryTopicOf> <${file_doc//\//\\/}> \./\1/p")

./create-csv-import.sh -b "$base" -f "$cert_pem_file" -p "$cert_password" --title "$title" --slug "$import_slug" --action "$action" --query "$query" --file "$file" --delimiter "," # TO-DO: "${request_base}imports"