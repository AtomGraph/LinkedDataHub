#!/bin/bash

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pwd=$(realpath -s "$PWD")

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# add agent to the writers group

./add-agent-to-group.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

popd > /dev/null

pushd . > /dev/null && cd "$SCRIPT_ROOT/imports"

# create file

file_content_type="text/csv"

file_doc=$(./create-file.sh \
-f "$AGENT_CERT_FILE" \
-p "$AGENT_CERT_PWD" \
-b "$END_USER_BASE_URL" \
--title "Test CSV" \
--file "$pwd/test.csv" \
--file-content-type "${file_content_type}")

pushd . > /dev/null && cd "$SCRIPT_ROOT"

file_doc_ntriples=$(./get-document.sh \
  -f "$AGENT_CERT_FILE" \
  -p "$AGENT_CERT_PWD" \
  --accept 'application/n-triples' \
  "$file_doc")

popd > /dev/null

# echo "FILE NTRIPLES: $file_doc_ntriples"

file=$(echo "$file_doc_ntriples" | sed -rn "s/<(.*)> <http:\/\/xmlns.com\/foaf\/0.1\/isPrimaryTopicOf> <${file_doc//\//\\/}> \./\1/p")

#file=$(echo "$file_doc_ntriples" \
#| grep '<http://xmlns.com/foaf/0.1/primaryTopic>' \
#| cut -d " " -f 3 \
#| cut -d "<" -f 2 \
#| cut -d ">" -f 1) # cut < > to get URI

echo "$file" # file URL used in other tests

curl --head -k -w "%{http_code}\n" -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: ${file_content_type}" \
  "$file" \
| grep -q "$STATUS_OK"