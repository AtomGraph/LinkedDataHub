#!/bin/bash

args=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
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

ns="${base}ns#"
class=${base}ns#File
target=${base}files/?forClass=$(urlencode "$class")

# https://stackoverflow.com/questions/19116016/what-is-the-right-way-to-post-multipart-form-data-using-curl

rdf_post+="-F \"rdf=\" "
rdf_post+="-F \"sb=file\" "
rdf_post+="-F \"pu=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#fileName\" "
rdf_post+="-F \"ol=@${file};type=${file_content_type}\" "
rdf_post+="-F \"pu=http://purl.org/dc/terms/title\" "
rdf_post+="-F \"ol=${title}\" "
rdf_post+="-F \"pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type\" "
rdf_post+="-F \"ou=${ns}File\" "
rdf_post+="-F \"pu=https://www.w3.org/ns/ldt/document-hierarchy/domain#slug\" "
rdf_post+="-F \"ol=${file_slug}\" "
rdf_post+="-F \"pu=http://xmlns.com/foaf/0.1/isPrimaryTopicOf\" "
rdf_post+="-F \"ob=item\" "
rdf_post+="-F \"sb=item\" "
rdf_post+="-F \"pu=http://purl.org/dc/terms/title\" "
rdf_post+="-F \"ol=${title}\" "
rdf_post+="-F \"pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type\" "
rdf_post+="-F \"ou=${ns}FileItem\" "
rdf_post+="-F \"pu=http://xmlns.com/foaf/0.1/primaryTopic\" "
rdf_post+="-F \"ob=file\" "

if [ ! -z "$description" ] ; then
    rdf_post+="-F \"sb=file\" "
    rdf_post+="-F \"pu=http://purl.org/dc/terms/description\" "
    rdf_post+="-F \"ol=${description}\" "
fi
if [ ! -z "$slug" ] ; then
    rdf_post+="-F \"sb=item\" "
    rdf_post+="-F \"pu=https://www.w3.org/ns/ldt/document-hierarchy/domain#slug\" "
    rdf_post+="-F \"ol=${slug}\" "

fi
if [ ! -z "$file-slug" ] ; then
    rdf_post+="-F \"sb=file\" "
    rdf_post+="-F \"pu=https://www.w3.org/ns/ldt/document-hierarchy/domain#slug\" "
    rdf_post+="-F \"ol=${file-slug}\" "

fi

# POST RDF/POST multipart form from stdin to the server and print Location URL
echo -e $rdf_post+ | curl -v -k -H "Accept: text/turtle" -E ${cert_pem_file}:${cert_password} --config - $target -s -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'