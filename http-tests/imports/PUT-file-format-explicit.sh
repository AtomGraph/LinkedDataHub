#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

pwd=$(realpath "$PWD")

# add agent to the writers group

add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create test file with sample content

test_file=$(mktemp)
echo "test,data,sample" > "$test_file"
echo "1,2,3" >> "$test_file"
echo "4,5,6" >> "$test_file"

# upload file with explicit media type: text/plain

file_doc=$(create-file.sh \
-f "$AGENT_CERT_FILE" \
-p "$AGENT_CERT_PWD" \
-b "$END_USER_BASE_URL" \
--title "Test File for Media Type Update" \
--file "$test_file" \
--file-content-type "text/plain")

# get the file resource URI and initial dct:format

file_doc_ntriples=$(get.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$file_doc")

file_uri=$(echo "$file_doc_ntriples" | sed -rn "s/<${file_doc//\//\\/}> <http:\/\/xmlns.com\/foaf\/0.1\/primaryTopic> <(.*)> \./\1/p")

# get initial SHA1 hash
initial_sha1=$(echo "$file_doc_ntriples" | sed -rn "s/<${file_uri//\//\\/}> <http:\/\/xmlns.com\/foaf\/0.1\/sha1> \"(.*)\" \./\1/p")

# get initial dct:format
initial_format=$(echo "$file_doc_ntriples" | sed -rn "s/<${file_uri//\//\\/}> <http:\/\/purl.org\/dc\/terms\/format> <(.*)> \./\1/p")

# verify initial format is text/plain
if [[ ! "$initial_format" =~ text/plain ]]; then
    echo "ERROR: Initial format should contain text/plain but got: $initial_format"
    exit 1
fi

# re-upload the same file to the same document with different explicit media type: text/csv
# using PUT with RDF/POST multipart format
# IMPORTANT: Include explicit dct:format in RDF to simulate user editing the format field in the form

rdf_post=""
rdf_post+="-F \"rdf=\"\n"
rdf_post+="-F \"sb=file\"\n"
rdf_post+="-F \"pu=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#fileName\"\n"
rdf_post+="-F \"ol=@${test_file};type=text/csv\"\n"
rdf_post+="-F \"pu=http://purl.org/dc/terms/title\"\n"
rdf_post+="-F \"ol=Test File for Media Type Update\"\n"
rdf_post+="-F \"pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type\"\n"
rdf_post+="-F \"ou=http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#FileDataObject\"\n"
rdf_post+="-F \"pu=http://purl.org/dc/terms/format\"\n"
rdf_post+="-F \"ou=http://www.sparontologies.net/mediatype/text/csv\"\n"
rdf_post+="-F \"su=${file_doc}\"\n"
rdf_post+="-F \"pu=http://purl.org/dc/terms/title\"\n"
rdf_post+="-F \"ol=Test File for Media Type Update\"\n"
rdf_post+="-F \"pu=http://www.w3.org/1999/02/22-rdf-syntax-ns#type\"\n"
rdf_post+="-F \"ou=https://www.w3.org/ns/ldt/document-hierarchy#Item\"\n"
rdf_post+="-F \"pu=http://xmlns.com/foaf/0.1/primaryTopic\"\n"
rdf_post+="-F \"ob=file\"\n"
rdf_post+="-F \"pu=http://rdfs.org/sioc/ns#has_container\"\n"
rdf_post+="-F \"ou=${END_USER_BASE_URL}files/\"\n"

echo -e "$rdf_post" | curl -f -v -s -k -X PUT -H "Accept: text/turtle" -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" -o /dev/null --config - "$file_doc"

# get updated document

updated_ntriples=$(get.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$file_doc")

# get updated SHA1 hash (should be same as initial)
updated_sha1=$(echo "$updated_ntriples" | sed -rn "s/<${file_uri//\//\\/}> <http:\/\/xmlns.com\/foaf\/0.1\/sha1> \"(.*)\" \./\1/p")

# get updated dct:format (should be text/csv)
updated_format=$(echo "$updated_ntriples" | sed -rn "s/<${file_uri//\//\\/}> <http:\/\/purl.org\/dc\/terms\/format> <(.*)> \./\1/p")

# verify SHA1 is unchanged (same file content)
if [ "$initial_sha1" != "$updated_sha1" ]; then
    echo "ERROR: SHA1 hash changed! Initial: $initial_sha1, Updated: $updated_sha1"
    exit 1
fi

# verify dct:format was updated to text/csv
if [[ ! "$updated_format" =~ text/csv ]]; then
    echo "ERROR: Format should have been updated to text/csv but got: $updated_format"
    exit 1
fi

# cleanup
rm -f "$test_file"
