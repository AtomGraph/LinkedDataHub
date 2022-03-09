#!/usr/bin/env bash
set -euo pipefail

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

pushd . > /dev/null && cd "$SCRIPT_ROOT"

# create container

container=$(./create-container.sh \
-f "$AGENT_CERT_FILE" \
-p "$AGENT_CERT_PWD" \
-b "$END_USER_BASE_URL" \
--title "Concepts" \
--slug "concepts" \
--parent "$END_USER_BASE_URL")

# import RDF

cd imports

./import-rdf.sh \
-f "$AGENT_CERT_FILE" \
-p "$AGENT_CERT_PWD" \
-b "$END_USER_BASE_URL" \
--title "Test" \
--query-file "$pwd/rdf-test.rq" \
--file "$pwd/test.ttl" \
--file-content-type "text/turtle" \
--action "$container"

popd > /dev/null

rdf_id="concept7367"
rdf_value="http://vocabularies.unesco.org/thesaurus/concept7367"

# wait until the imported item appears (since import is executed asynchronously)

counter=20
i=0

while [ "$i" -lt "$counter" ] && ! curl -k -s -f -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" "${container}${rdf_id}/" -H "Accept: application/n-triples" >/dev/null 2>&1
do
    sleep 1 ;
    i=$(( i+1 ))

    echo "Waited ${i}s..."
done

# check item properties

curl -k -f -s -N \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "${container}${rdf_id}/" \
| grep -q "<${container}${rdf_id}/> <http://xmlns.com/foaf/0.1/primaryTopic> <${rdf_value}>"