#!/usr/bin/env bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_cache "$END_USER_VARNISH_SERVICE"
purge_cache "$ADMIN_VARNISH_SERVICE"
purge_cache "$FRONTEND_VARNISH_SERVICE"

# An import's mapping query is executed by the platform itself, so a SERVICE clause in it is fetched from inside the
# platform container rather than from the triplestore. It must not reach the internal admin store: whoever can create
# an import could otherwise copy agents and authorizations into the documents it creates.
# rdf-service-internal.rq always constructs the item, and gives its leak triple a value only if the admin store answered

pwd=$(realpath "$PWD")

# add agent to the writers group

ldh admin add agent \
  -f "$OWNER_CERT_KEYSTORE" \
  -p "$OWNER_CERT_PWD" \
  --agent "$AGENT_URI" \
  "${ADMIN_BASE_URL}acl/groups/writers/"

# create import item

item=$(ldh create item \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "RDF import with SERVICE" \
  --container "$END_USER_BASE_URL")

# create target container

container=$(ldh create container \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "SERVICE import" \
  --slug "service-internal" \
  --parent "$END_USER_BASE_URL")

# import RDF with the mapping query that uses SERVICE

ldh import rdf \
  -f "$AGENT_CERT_KEYSTORE" \
  -p "$AGENT_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test" \
  --query-file "$pwd/rdf-service-internal.rq" \
  --rdf-file "$pwd/test.ttl" \
  --content-type "text/turtle" \
  "$item"

imported="${container}item/"

# wait until the imported item appears (since import is executed asynchronously)

counter=20
i=0

while [ "$i" -lt "$counter" ] && ! curl -k -s -f -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" "$imported" -H "Accept: application/n-triples" >/dev/null 2>&1
do
    sleep 1 ;
    i=$(( i+1 ))

    echo "Waited ${i}s..."
done

document=$(curl -k -f -s \
  -E "$AGENT_CERT_FILE":"$AGENT_CERT_PWD" \
  -H "Accept: application/n-triples" \
  "$imported") || { echo "The imported item ${imported} did not appear"; exit 1; }

echo "DEBUG: ${imported}: ${document}"

# check that nothing from the admin store was imported

if grep -q '<urn:test:leak>' <<< "$document"; then
    echo "SERVICE <http://fuseki:3030/admin/> in an import mapping returned data"
    exit 1
fi
