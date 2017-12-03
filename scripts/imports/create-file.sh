#!/bin/bash

# https://stackoverflow.com/questions/19116016/what-is-the-right-way-to-post-multipart-form-data-using-curl
# multipart reikia tik tada, kai failai uploadinami

if [ "$#" -ne 8 ]; then
  echo "Usage:   $0 base cert_pem_file cert_password title doc_slug file_slug file type" >&2
  echo "Example: $0" 'https://linkeddatahub.com/my-context/my-dataspace/ linkeddatahub.pem Password "Friends" 44f18281-6afa-408e-a7c4-bad38487f198 646af756-a49f-40da-a25e-ea8d81f6d306 friends.csv text/csv' >&2
  exit 1
fi

urlencode()
{
  echo $(python -c 'import urllib, sys; print urllib.quote(  sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])' $1)
}

base=$1
cert_pem_file=$2
cert_password=$3
ns="${base}ns#"
class=${base}ns#File
target=${base}files/?forClass=$(urlencode "$class")
title=$4
doc_slug=$5
file_slug=$6
file=$7
type=$8

curl -v -k \
-H "Accept: text/turtle" \
-E ${cert_pem_file}:${cert_password} \
-F "rdf=" \
-F "sb=file" \
-F "pu=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#fileName" \
-F "ol=@${file};type=${type}" \
-F "pu=http://purl.org/dc/terms/title" \
-F "ol=${title}" \
-F "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
-F "ou=${ns}File" \
-F "pu=https://www.w3.org/ns/ldt/document-hierarchy/domain#slug" \
-F "ol=${file_slug}" \
-F "pu=http://xmlns.com/foaf/0.1/isPrimaryTopicOf" \
-F "ob=item" \
-F "sb=item" \
-F "pu=http://purl.org/dc/terms/title" \
-F "ol=${title}" \
-F "pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type" \
-F "ou=${ns}FileItem" \
-F "pu=https://www.w3.org/ns/ldt/document-hierarchy/domain#slug" \
-F "ol=${doc_slug}" \
-F "pu=http://xmlns.com/foaf/0.1/primaryTopic" \
-F "ob=file" \
$target -s -D - | tr -d '\r' | sed -En 's/^Location: (.*)/\1/p'