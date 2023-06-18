#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

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
  --file "$pwd/test.ttl" \
  --file-content-type "text/turtle" \
  --graph "$container"

popd > /dev/null

# wait until the imported data appears (since import is executed asynchronously)

counter=20
i=0
test_triples=""

while [ "$i" -lt "$counter" ] && [ -z "$test_triples" ]
do
    # check item properties

    test_triples=$(curl -G -k -f -s -N \
      -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
      -H "Accept: application/n-triples" \
      "$container" \
    | grep "<http://vocabularies.unesco.org/thesaurus/concept7367> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2004/02/skos/core#Concept>" || [[ $? == 1 ]])

    sleep 1 ;
    i=$(( i+1 ))

    echo "Waited ${i}s..."
done

if [ "$i" = "$counter" ]; then
  exit 1
fi
