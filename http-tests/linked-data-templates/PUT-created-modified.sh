#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

pushd . > /dev/null && cd "$SCRIPT_ROOT"

# create a document

container=$(./create-container.sh \
-f "$AGENT_CERT_FILE" \
-p "$AGENT_CERT_PWD" \
-b "$END_USER_BASE_URL" \
--title "Test" \
--slug "test" \
--parent "$END_USER_BASE_URL" \
"$END_USER_BASE_URL")

# get the dct:created value

container_ntriples=$(./get-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$container")

created=$(echo "$container_ntriples" \
| grep '<http://purl.org/dc/terms/created>' \
| cut -d " " -f 3)

[ -z "$created" ] && exit 1 # fail if dct:created value is missing

# get the named graph URI

graph_doc=$(echo "$container_ntriples" \
| sed -rn "s/<${container//\//\\/}> <http:\/\/rdfs\.org\/ns\/void#inDataset> <(.*)#this> \./\1/p")

# get the named graph triples

graph_ntriples=$(./get-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$graph_doc")

# put the same triples in the named graph to add dct:modified

pushd . > /dev/null && cd "$SCRIPT_ROOT"

echo "$graph_ntriples" \
| ./update-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --content-type 'application/n-triples' \
  "$graph_doc"

updated_container_ntriples=$(./get-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$container")

popd > /dev/null

# check that dct:created was added but dct:modified is not there

updated_created=$(echo "$updated_container_ntriples" \
| grep '<http://purl.org/dc/terms/created>' \
| grep -v '<http://purl.org/dc/terms/modified>' \
| cut -d " " -f 3)

# fail if dct:created value changed

if [ "$created" != "$updated_created" ]; then
    exit 1
fi

# get dct:modified value

modified=$(echo "$updated_container_ntriples" \
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