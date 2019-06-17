#!/bin/bash

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
    echo '-f|--cert_pem_file not set'
    # print_usage
    exit 1
fi
if [ -z "$cert_password" ] ; then
    echo '-p|--cert-password not set'
    # print_usage
    exit 1
fi
if [ -z "$file_content_type" ] ; then
    echo '--file-content-type not set'
    # print_usage
    exit 1
fi
if [ -z "$base" ] ; then
    echo '-b|--base not set'
    exit 1
fi
if [ -z "$title" ] ; then
    echo '--title not set'
    exit 1
fi
if [ -z "$file" ] ; then
    echo '--file not set'
    exit 1
fi
if [ -z "$file_content_type" ] ; then
    echo '--file-content-type not set'
    exit 1
fi

urlencode()
{
  echo $(python -c 'import urllib, sys; print urllib.quote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])' $1)
}

ns="${base}ns#"
class="${base}ns#File"
target=${base}files/?forClass=$(urlencode "$class")

# https://stackoverflow.com/questions/19116016/what-is-the-right-way-to-post-multipart-form-data-using-curl

# rdf_post+="-v -k -H "Accept: text/turtle" -E ${cert_pem_file}:${cert_password} "
rdf_post+="-F \"rdf=\"\n"
rdf_post+="-F \"sb=file\"\n"
rdf_post+="-F \"pu=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#fileName\"\n"
rdf_post+="-F \"ol=@${file};type=${file_content_type}\"\n"
rdf_post+="-F \"pu=http://purl.org/dc/terms/title\"\n"
rdf_post+="-F \"ol=${title}\"\n"
rdf_post+="-F \"pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type\"\n"
rdf_post+="-F \"ou=${ns}File\"\n"
rdf_post+="-F \"pu=https://www.w3.org/ns/ldt/document-hierarchy/domain#slug\"\n"
rdf_post+="-F \"ol=${file_slug}\"\n"
rdf_post+="-F \"pu=http://xmlns.com/foaf/0.1/isPrimaryTopicOf\"\n"
rdf_post+="-F \"ob=item\"\n"
rdf_post+="-F \"sb=item\"\n"
rdf_post+="-F \"pu=http://purl.org/dc/terms/title\"\n"
rdf_post+="-F \"ol=${title}\"\n"
rdf_post+="-F \"pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type\"\n"
rdf_post+="-F \"ou=${ns}FileItem\"\n"
rdf_post+="-F \"pu=http://xmlns.com/foaf/0.1/primaryTopic\"\n"
rdf_post+="-F \"ob=file\"\n"

if [ -n "$description" ] ; then
    rdf_post+="-F \"sb=file\"\n"
    rdf_post+="-F \"pu=http://purl.org/dc/terms/description\"\n"
    rdf_post+="-F \"ol=${description}\"\n"
fi
if [ -n "$slug" ] ; then
    rdf_post+="-F \"sb=item\"\n"
    rdf_post+="-F \"pu=https://www.w3.org/ns/ldt/document-hierarchy/domain#slug\"\n"
    rdf_post+="-F \"ol=${slug}\"\n"

fi
if [ -n "$file_slug" ] ; then
    rdf_post+="-F \"sb=file\"\n"
    rdf_post+="-F \"pu=https://www.w3.org/ns/ldt/document-hierarchy/domain#slug\"\n"
    rdf_post+="-F \"ol=${file_slug}\"\n"

fi

# POST RDF/POST multipart form from stdin to the server and print Location URL
echo -e $rdf_post | curl -v -k -H "Accept: text/turtle" -E ${cert_pem_file}:${cert_password} --config - $target -s -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'