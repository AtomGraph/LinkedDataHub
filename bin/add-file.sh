#!/usr/bin/env bash
set -eo pipefail

print_usage()
{
    printf "Uploads a file.\n"
    printf "\n"
    printf "Usage:  %s options TARGET_URI\n" "$0"
    printf "\n"
    printf "Options:\n"
    printf "  -f, --cert-pem-file CERT_FILE        .pem file with the WebID certificate of the agent\n"
    printf "  -p, --cert-password CERT_PASSWORD    Password of the WebID certificate\n"
    printf "  -b, --base BASE_URI                  Base URI of the application\n"
    printf "  --proxy PROXY_URL                    The host this request will be proxied through (optional)\n"
    printf "\n"
    printf "  --title TITLE                        Title of the file\n"
    printf "  --description DESCRIPTION            Description of the file (optional)\n"
    printf "\n"
    printf "  --file ABS_PATH                      Absolute path to the file\n"
    printf "  --content-type MEDIA_TYPE            Media type of the file (optional)\n"
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
        --description)
        description="$2"
        shift # past argument
        shift # past value
        ;;
        --file)
        file="$2"
        shift # past argument
        shift # past value
        ;;
        --content-type)
        content_type="$2"
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
if [ -z "$file" ] ; then
    print_usage
    exit 1
fi
if [ -z "$content_type" ] ; then
    # determine content-type if not provided
    content_type=$(file -b --mime-type "$file")
fi

# https://stackoverflow.com/questions/19116016/what-is-the-right-way-to-post-multipart-form-data-using-curl

rdf_post+="-F \"rdf=\"\n"
rdf_post+="-F \"sb=file\"\n"
rdf_post+="-F \"pu=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#fileName\"\n"
rdf_post+="-F \"ol=@${file};type=${content_type}\"\n"
rdf_post+="-F \"pu=http://purl.org/dc/terms/title\"\n"
rdf_post+="-F \"ol=${title}\"\n"
rdf_post+="-F \"pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type\"\n"
rdf_post+="-F \"ou=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#FileDataObject\"\n"

if [ -n "$description" ] ; then
    rdf_post+="-F \"pu=http://purl.org/dc/terms/description\"\n"
    rdf_post+="-F \"ol=${description}\"\n"
fi

# rewrite target URL *after* building the request body (which does not need the rewritten URLs)

if [ -n "$proxy" ]; then
    # rewrite target hostname to proxy hostname
    target_host=$(echo "$target" | cut -d '/' -f 1,2,3)
    proxy_host=$(echo "$proxy" | cut -d '/' -f 1,2,3)
    target="${target/$target_host/$proxy_host}"
fi

# POST RDF/POST multipart form
echo -e "$rdf_post" | curl -f -v -s -k -X POST -H "Accept: text/turtle" -E "$cert_pem_file":"$cert_password" -o /dev/null --config - "$target"
