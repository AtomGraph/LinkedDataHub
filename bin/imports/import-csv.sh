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
    printf "Usage:  %s options TARGET_URI\n" "$0"
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
    printf "  --csv-file ABS_PATH                  Absolute path to the CSV file\n"
    printf "  --delimiter CHAR                     CSV delimiter char (default: ',')\n"
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
        --csv-file)
        csv_file="$2"
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

target="$1"

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
if [ -z "$csv_file" ] ; then
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

# Add the CONSTRUCT query to the item using fragment identifier
add-construct.sh \
  -b "$base" \
  -f "$cert_pem_file" \
  -p "$cert_password" \
  --proxy "$proxy" \
  --title "$title" \
  --uri "#${query_id}" \
  --query-file "$query_file" \
  "$target"

# The query URI is the document with fragment
query="${target}#${query_id}"

# Add the file to the import item
add-file.sh \
  -b "$base" \
  -f "$cert_pem_file" \
  -p "$cert_password" \
  --proxy "$proxy" \
  --title "$title" \
  --file "$csv_file" \
  --content-type "text/csv" \
  "$target"

# Calculate file URI from SHA1 hash
sha1sum=$(shasum -a 1 "$csv_file" | awk '{print $1}')
file="${base}uploads/${sha1sum}"

# Add the import metadata to the import item using fragment identifier
add-csv-import.sh \
  -b "$base" \
  -f "$cert_pem_file" \
  -p "$cert_password" \
  --proxy "$proxy" \
  --title "$title" \
  --query "$query" \
  --file "$file" \
  --delimiter "$delimiter" \
  "$target"
  