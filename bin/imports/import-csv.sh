#!/usr/bin/env bash
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
    printf "\n"
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
        --proxy)
        proxy="$2"
        shift # past argument
        shift # past value
        ;;
        --title)
        title="$2"
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
if [ -z "$query_file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$delimiter" ] ; then
    delimiter=','
fi

if [ -z "$proxy" ] ; then
    proxy="$base"
fi

# Generate query ID for fragment identifier
query_id=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Create the imports/ container first (ignore error if it already exists)
create-container.sh \
  -b "$base" \
  -f "$cert_pem_file" \
  -p "$cert_password" \
  --proxy "$proxy" \
  --title "Imports" \
  --parent "$base" \
  --slug "imports" 2>/dev/null || true

# Create the import item document
import_doc=$(create-item.sh \
  -b "$base" \
  -f "$cert_pem_file" \
  -p "$cert_password" \
  --proxy "$proxy" \
  --title "$title" \
  --container "${base}imports/" \
  --slug "$query_doc_slug"
)

# Add the CONSTRUCT query to the item using fragment identifier
add-construct.sh \
  -b "$base" \
  -f "$cert_pem_file" \
  -p "$cert_password" \
  --proxy "$proxy" \
  --title "$title" \
  --uri "#${query_id}" \
  --query-file "$query_file" \
  "$import_doc"

# The query URI is the document with fragment
query="${import_doc}#${query_id}"

# Add the file to the import item
add-file.sh \
  -b "$base" \
  -f "$cert_pem_file" \
  -p "$cert_password" \
  --proxy "$proxy" \
  --title "$title" \
  --file "$file" \
  --file-content-type "text/csv" \
  "$import_doc"

# Calculate file URI from SHA1 hash
sha1sum=$(shasum -a 1 "$file" | awk '{print $1}')
file_uri="${base}uploads/${sha1sum}"

# Generate import ID for fragment identifier
import_id=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Add the import metadata to the import item using fragment identifier
add-csv-import.sh \
  -b "$base" \
  -f "$cert_pem_file" \
  -p "$cert_password" \
  --proxy "$proxy" \
  --title "$title" \
  --uri "#${import_id}" \
  --query "$query" \
  --file "$file_uri" \
  --delimiter "$delimiter" \
  "$import_doc"
  