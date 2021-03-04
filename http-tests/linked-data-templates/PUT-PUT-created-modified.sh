#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# create a random document slug

slug=$(uuidgen | tr '[:upper:]' '[:lower:]')

# add agent to the writers group to be able to read/write documents (might already be done by another test)

./create-authorization.sh \
-b "$ADMIN_BASE_URL" \
-f "$OWNER_CERT_FILE" \
-p "$OWNER_CERT_PWD" \
--label "Write test doc" \
--agent "$AGENT_URI" \
--to "${END_USER_BASE_URL}${slug}/" \
--write \
"${ADMIN_BASE_URL}acl/authorizations/"

popd > /dev/null

pushd . > /dev/null && cd "$SCRIPT_ROOT"

# create a document

read -d '' -r doc_turtle << EOF || true
    @prefix nsdd:    <ns/domain/default#> .
    @prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .
    @prefix dct:	<http://purl.org/dc/terms/> .
    @prefix sioc:	<http://rdfs.org/sioc/ns#> .

    <${slug}/> a nsdd:Item ;
        sioc:has_container <> ;
        dct:title "Test document" .
EOF

doc=$(echo "$doc_turtle" | turtle --base="$END_USER_BASE_URL" | ./update-document.sh \
-f "$AGENT_CERT_FILE" \
-p "$AGENT_CERT_PWD" \
-t "application/n-triples" \
"${END_USER_BASE_URL}${slug}/")

# get the dct:created value

doc_ntriples=$(./get-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$doc")

created=$(echo "$doc_ntriples" \
| grep '<http://purl.org/dc/terms/created>' \
| cut -d " " -f 3)

[ -z "$created" ] && exit 1 # fail if dct:created value is missing

# put the same triples back into the document to add dct:modified (to the meta-graph)

pushd . > /dev/null && cd "$SCRIPT_ROOT"

echo "$doc_ntriples" \
| ./update-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --content-type 'application/n-triples' \
  "$doc"

updated_doc_ntriples=$(./get-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$doc")

popd > /dev/null

# check that dct:created was added but dct:modified is not there

updated_created=$(echo "$updated_doc_ntriples" \
| grep '<http://purl.org/dc/terms/created>' \
| grep -v '<http://purl.org/dc/terms/modified>' \
| cut -d " " -f 3)

# fail if dct:created value changed

if [ "$created" != "$updated_created" ]; then
    exit 1
fi

# check that dct:modified was added

modified=$(echo "$updated_doc_ntriples" \
| grep '<http://purl.org/dc/terms/modified>' \
| cut -d " " -f 3 \
| cut -d "\"" -f 2) # cut quotes and datatype

# fail if dct:modified value is missing

if [ -z "$modified" ]; then
    exit 1
fi

created=$(echo "$created" | cut -d "\"" -f 2) # cut quotes and datatype

# check that "$modified" is actually later than "$created"

created_date=$(date --date="$created" +%s)
modified_date=$(date --date="$modified" +%s)

if [ "$created_date" -gt "$modified_date" ]; then
    exit 1
fi