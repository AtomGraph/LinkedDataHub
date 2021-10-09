#!/bin/bash

print_usage()
{
    printf "Uploads a file.\n"
    printf "\n"
    printf "Usage:  %s options [TARGET_URI]\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "\n"
    printf "  --title TITLE                        Title of the file\n"
    printf "  --description DESCRIPTION            Description of the file (optional)\n"
    printf "  --slug STRING                        String that will be used as URI path segment (optional)\n"
    printf "\n"
    printf "  --file ABS_PATH                      Absolute path to the file\n"
    printf "  --file-content-type MEDIA_TYPE       Media type of the file\n"
    #printf "  --file-slug STRING                   String that will be used as the file's URI path segment (optional)\n"
}

hash curl 2>/dev/null || { echo >&2 "curl not on \$PATH. Aborting."; exit 1; }

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
        -t|--content-type)
        content_type="$2"
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
        --file)
        file="$2"
        shift # past argument
        shift # past value
        ;;
        --file-content-type)
        file_content_type="$2"
        shift # past argument
        shift # past value
        ;;
        --file-slug)
        file_slug="$2"
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
if [ -z "$file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$file_content_type" ] ; then
    print_usage
    exit 1
fi

ns="https://w3id.org/atomgraph/linkeddatahub/default#"
class="${ns}File"
container="${base}files/"

if [ -z "$1" ]; then
    target="${base}service" # default target URL = graph store
else
    target="$1"
fi

# need to create explicit file URI since that is what this script returns (not the graph URI)

if [ -z "$file_slug" ] ; then
    file_slug=$(uuidgen)
fi

# https://stackoverflow.com/questions/19116016/what-is-the-right-way-to-post-multipart-form-data-using-curl

rdf_post+="-F \"rdf=\"\n"
rdf_post+="-F \"sb=file\"\n"
rdf_post+="-F \"pu=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#fileName\"\n"
rdf_post+="-F \"ol=@${file};type=${file_content_type}\"\n"
rdf_post+="-F \"pu=http://purl.org/dc/terms/title\"\n"
rdf_post+="-F \"ol=${title}\"\n"
rdf_post+="-F \"pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type\"\n"
rdf_post+="-F \"ou=${class}\"\n"
rdf_post+="-F \"pu=http://xmlns.com/foaf/0.1/isPrimaryTopicOf\"\n"
rdf_post+="-F \"ob=item\"\n"
rdf_post+="-F \"sb=item\"\n"
rdf_post+="-F \"pu=http://purl.org/dc/terms/title\"\n"
rdf_post+="-F \"ol=${title}\"\n"
rdf_post+="-F \"pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type\"\n"
rdf_post+="-F \"ou=${ns}Item\"\n"
rdf_post+="-F \"pu=http://rdfs.org/sioc/ns#has_container\"\n"
rdf_post+="-F \"ou=${container}\"\n"

if [ -n "$description" ] ; then
    rdf_post+="-F \"sb=file\"\n"
    rdf_post+="-F \"pu=http://purl.org/dc/terms/description\"\n"
    rdf_post+="-F \"ol=${description}\"\n"
fi
if [ -n "$file_slug" ] ; then
    rdf_post+="-F \"sb=file\"\n"
    rdf_post+="-F \"pu=https://www.w3.org/ns/ldt/document-hierarchy/domain#slug\"\n"
    rdf_post+="-F \"ol=${file_slug}\"\n"

fi

# POST RDF/POST multipart form from stdin to the server
echo -e "$rdf_post" | curl -s -k -H "Accept: text/turtle" -E "$cert_pem_file":"$cert_password" --config - "$target" -v -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'